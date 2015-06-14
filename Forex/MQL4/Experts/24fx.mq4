//+------------------------------------------------------------------+
//|                                                         24fx.mq4 |
//|                                                             Dzam |
//|                                                                  |
//+------------------------------------------------------------------+
//Hystory data should be for 2 last days
//#import "kernel32.dll"
//   int GetLastError();
//#import

#property copyright "Dzam"
#property version   "2.4"
#property strict

//--- input parameters
input bool     _fixLotSize          = false;
input double   _lotSize             = 0.01;
input int      _magicNumber         = 777111;
input int      _dataUpdateInterval  = 5;        //In minutes
input bool     _writeToTestFile     = false;
input double   _riskPerTrade        = 1;        //Risk per order (%)
input int      _timeShift           = 0;       //From Moscow
input string   _workHours           = "0,2,4,8,12,13,14,15,16,20,23";

input string   _symbolPostfix        = "";
//--- 

string      version              =  "2.4";

string      tableString;
string      tableStrings[];

datetime    lastDataLoadTime     = NULL;

string      cookie               = "";          //���� ���������� ����

int workHours[]; //������ ������� �����

int LogFileHandle;            //��������� �� ���� �����

enum OrderStatus
{
	worked,		//����� � ������� ���������. ���� ��� �� ���������, �� ����� ������������ ��������.
				//	NULL -> worked.		������������� ����� ��� ���������� ���������� �� ���������.
				//	paused -> worked.	������ ����� ���� ��������, ���� ����� ��� � ��������� �����, �� ������� � ��������� ������ � �������� �������� ���
	canceled, 	//�������. ����� ������ �� ��������������. ���� ���������� �������.	
				//	paused -> canceled.	���� ������� �������������, ���� � ���������� ��� ���� ����������� ����� �� ���� �����, � ����� ������ �� ����� ��� �����
            // worked -> canceled. ���� �� ������ �������� ������, �� ���� ����� �� ������� ����� ��� ����, �� �������� �����.				   
	paused,		//����� � ��������� �����.
				//	worked -> paused.	����� ������� �� ������� worked, ���� ����� ��� �� ������, �� ������� � �������� �� �������� ���
	market		//����� � �����. ��� ����� ������� ������ �� ����� ��� ������ � �������. ��� ������������� � ���������� ���������
				//	worked -> market
};

struct order
{
   datetime    openTime;
   datetime    cancelTime;
   double      tpPrice;
   double      slPrice;
   double      enPrice;
   string      symbol;
   string      type;       	//"buy" or "sell"
   bool        processed;  	//true/false
   OrderStatus orderStatus;	//Enum
   int         ticket;     	//order ticket
};

class clOrderManager
{
   private:
      order    orders[9];
      double   lotSize;
      int      magicNumber;
      bool     fixLotSize;
      double   riskPerTrade;      
      int 	   workHours[];
      
      // ������� �������� ���-�� ����� � ������ ����� �� ������ /(���� � �������)
      double GetQuantity(double iStopSize, double iDeposit, double iRisk, int iLotDecimal, string iSymbol)
      {
              
         if(iStopSize != 0
            && MarketInfo(iSymbol, MODE_TICKVALUE) != 0)
         {
            return NormalizeDouble(iDeposit * iRisk / 100 / iStopSize / MarketInfo(iSymbol, MODE_TICKVALUE), iLotDecimal); //������������ ��� ������ �� �����
            
         }else
         {
            Print("Err: Symbol = " + iSymbol + ", stopSize = " + iStopSize + ", TV = " + MarketInfo(iSymbol, MODE_TICKVALUE));
            return 0;
         }
      }
      
	//��������� ����� �� �������� worked
	void checkWorkedStatus(int orderIndex)
    {
    
      /*
      //�������� ����� �� ������
		int orderBarShift;
				
		orderBarShift = iBarShift(orders[orderIndex].symbol, PERIOD_M1, orders[orderIndex].openTime, false);
      */
      
      //Print(orders[orderIndex].ticket + " / " + orderBarShift);
		//���� ����� � ������ ����� 0, �� ����� ��� ������ �� ����������, �������� �����
      if(orders[orderIndex].ticket == 0)
      {
            /*
         	for(int i = 0; i <= orderBarShift; i++)
         	{
         		//���� ���� ����� ����� High � Low, �� ��������� �����
         		if(orders[orderIndex].enPrice >= iLow(orders[orderIndex].symbol, PERIOD_M1, i)
         			&& orders[orderIndex].enPrice <= iHigh(orders[orderIndex].symbol, PERIOD_M1, i))
         		{
         		   WriteLog(LogFileHandle, "---checkWorkedStatus. Change status for Symbol = " + string(orders[orderIndex].symbol) + ", OldStatus =  " + string(orders[orderIndex].orderStatus) + ", NewStatus =  " + string(canceled) + ", index = " + string(i));
         			orders[orderIndex].orderStatus = canceled;
         			//���� ����� ��������, �� ������ ��� ������ ���-�� ���������
         			return;
         		}
         	}
         	*/
         	
         //���� ������� ��� �� �������, �� ��������� ����� � ����� �����
         if(!arraySearch(workHours, Hour()))
         {
            WriteLog(LogFileHandle, "---checkWorkedStatus. Change status for Symbol = " + string(orders[orderIndex].symbol) + ", OldStatus =  " + string(orders[orderIndex].orderStatus) + ", NewStatus =  " + string(paused));
            orders[orderIndex].orderStatus = paused;
         }
         
         //���� ����� �������, �� ����� ��������� �� �����
         return;
      }
    
      	  
		//�������� �� � ����� �� ��� ��� �����
		if(OrderSelect(orders[orderIndex].ticket, SELECT_BY_TICKET, MODE_TRADES))
		{
			if(OrderType() == OP_BUY
				|| OrderType() == OP_SELL)
			{
				WriteLog(LogFileHandle, "---checkWorkedStatus. Change status for Symbol = " + string(orders[orderIndex].symbol) + ", OldStatus =  " + string(orders[orderIndex].orderStatus) + ", NewStatus =  " + string(market));
				orders[orderIndex].orderStatus = market;
				//���� ����� � �����, �� ������ ������ ������ �� �����.
				return;
			}
			else //���� ��� ���������
			{
			   //���� ��� �������� ��������, �� ������ ��������� ��� ������ canceled
			   if(TimeCurrent() > orders[orderIndex].cancelTime)
			   {
			      orders[orderIndex].orderStatus = canceled;
			      return;
			   }
			   
				//���� ������� ��� �� �������, �� ��������� ����� � ����� �����
				if(!arraySearch(workHours, Hour()))
				{
					//�������� �������� �����
					WriteLog(LogFileHandle, "---checkWorkedStatus. Try to cancel order Symbol = " + string(orders[orderIndex].symbol));
					bool isDeleted = OrderDelete(orders[orderIndex].ticket);

					if(isDeleted)
					{
						WriteLog(LogFileHandle, "---checkWorkedStatus. Change status for Symbol = " + string(orders[orderIndex].symbol) + ", OldStatus =  " + string(orders[orderIndex].orderStatus) + ", NewStatus =  " + string(paused));
						orders[orderIndex].orderStatus = paused;
						orders[orderIndex].processed = false;
					}
				}
			}
		}      	  
	}
      
	//��������� ����� �� �������� paused
	void checkPausedStatus(int orderIndex)
	{
	   /*
		//�������� ����� �� ������
		int orderBarShift;
		bool shouldCancel;
		
		orderBarShift = iBarShift(orders[orderIndex].symbol, PERIOD_M1, orders[orderIndex].openTime, false);
		shouldCancel = false;
		for(int i = 0; i <= orderBarShift; i++)
		{
			//���� ���� ����� ����� High � Low, �� ��������� �����
			if(orders[orderIndex].enPrice >= iLow(orders[orderIndex].symbol, PERIOD_M1, i)
				&& orders[orderIndex].enPrice <= iHigh(orders[orderIndex].symbol, PERIOD_M1, i))
			{
				orders[orderIndex].orderStatus = canceled;				
				//���� ����� ��������, �� ������ ��� ������ ���-�� ���������
				return;
			}
		}
		*/
		
		//�������� ������ �� ����� ������� �������. ������� ��� �������� �������
		if(arraySearch(workHours, Hour()))
		{
		   sendOrder(orders[orderIndex]);
		   
		   //���� ����� ���������, �� ������ ������
		   if(orders[orderIndex].processed)
		   {
			   orders[orderIndex].orderStatus = worked;
         }
		}
	}
      
      //��������� � ������������� ������ ������ �� �������
      void checkStatus(int orderIndex)
      {
         //Print("Symbol = " + string(orders[orderIndex].symbol) + ", status = " + string(orders[orderIndex].orderStatus) + ", index = " + string(orderIndex));
      	  switch(orders[orderIndex].orderStatus)
      	  {
      	  	  case worked:
      	  	  	checkWorkedStatus(orderIndex);
      	  	  	break;
      	  	  	
      	  	  case paused:
      	  	  	checkPausedStatus(orderIndex);
      	  	  	break;
      	  	  	
      	  	  //��� ��������� ������� �� ���������
      	  	  default:
      	  	  	break;
      	  }
      }
   
   public:
      void initialize(double iLotSize, int iMagigNumber, bool iFixLotSize, double iRiskPerTrade, int &workHours[])
      {
         this.lotSize      = iLotSize;
         this.magicNumber  = iMagigNumber;
         this.fixLotSize   = iFixLotSize;
         this.riskPerTrade = iRiskPerTrade;
         ArrayCopy(this.workHours, workHours, 0, 0, ArraySize(workHours));
         
      }
      
      void updateData(order & iOrder)
      {
         int index = -1;
         
         
         if(iOrder.symbol == "NZDUSD" + _symbolPostfix)
         {
            index = 0;
            
         } else
         if(iOrder.symbol == "USDJPY" + _symbolPostfix)
         {       
            index = 1;
            
         } else
         if(iOrder.symbol == "EURUSD" + _symbolPostfix)
         {       
            index = -1;
            
         } else
         if(iOrder.symbol == "USDCAD" + _symbolPostfix)
         {       
            index = 3;
            
         } else
         if(iOrder.symbol == "AUDUSD" + _symbolPostfix)
         {       
            index = 4;
            
         } else
         if(iOrder.symbol == "USDCHF" + _symbolPostfix)
         {       
            index = 5;
            
         } else
         if(iOrder.symbol == "GBPCHF" + _symbolPostfix)
         {       
            index = 6;
            
         } else
         if(iOrder.symbol == "EURJPY" + _symbolPostfix)
         {       
            index = 7;
            
         } else
         if(iOrder.symbol == "GBPUSD" + _symbolPostfix)
         {       
            index = -1;
            
         }
         
         //Print(index + ", " + iOrder.type + ", /" + iOrder.symbol + "/");
         
         if(index != -1)
         {
            //WriteLog(LogFileHandle, "---Update data. Symbol = " + string(orders[index].symbol) + ", OldOrderOpenTime =  " + string(orders[index].openTime) + ", NewOrderOpenTime =  " + string(iOrder.openTime));
            if(orders[index].openTime < iOrder.openTime)
            {
               orders[index].processed = false;
               orders[index].orderStatus = worked;
               orders[index].ticket    = 0;
              WriteLog(LogFileHandle, "---Proceesed of " + string(orders[index].symbol) + " is " + string(orders[index].processed));
            }
            
            
            
            orders[index].cancelTime = iOrder.cancelTime;
            orders[index].enPrice    = iOrder.enPrice;
            orders[index].openTime   = iOrder.openTime;
            orders[index].slPrice    = iOrder.slPrice;
            orders[index].symbol     = iOrder.symbol;
            orders[index].tpPrice    = iOrder.tpPrice;
            orders[index].type       = iOrder.type;
            
            /*
            WriteLog(LogFileHandle, "---Update order / " + string(iOrder.openTime) + " / " +
                                                     string(iOrder.cancelTime) + " / "  +
                                                     string(iOrder.symbol) + " / " +
                                                     string(iOrder.enPrice) + " / " +
                                                     string(iOrder.tpPrice) + " / " +
                                                     string(iOrder.slPrice) + " / " +
                                                     string(index));
			*/
         }
      }
      
	void sendOrders()
	{
	 for(int i = 0; i < ArraySize(orders); i++)
	 {
		//����� ��������� ������� �������� �������
		checkStatus(i);

	    //WriteLog(LogFileHandle, "---Send orders. Symbol = " + string(orders[i].symbol) + ", Processed = " + string(orders[i].processed));            
	       //WriteLog(LogFileHandle, "---Send orders. Symbol = " + string(orders[i].symbol) + ", Ticket = " + string(orders[i].ticket));
	       if(orders[i].orderStatus == worked
	       	   && !OrderSelect(orders[i].ticket, SELECT_BY_TICKET))
	       {
	          //WriteLog(LogFileHandle, "---Send orders. Symbol = " + string(orders[i].symbol) + ", Error = " + string(GetLastError()));
	          sendOrder(orders[i]);
	          
	       }
			
			//if cancel time ,then cancel
			if(orders[i].orderStatus == market
				&& OrderSelect(orders[i].ticket, SELECT_BY_TICKET)
				&& OrderMagicNumber() == magicNumber
	            && OrderCloseTime() == 0
	            && TimeCurrent() >= orders[i].cancelTime)
	       {
	          
	             if(orders[i].type == "buy")
	             {
	                WriteLog(LogFileHandle, "---Close order. hClose1 = " + string(iClose(orders[i].symbol, PERIOD_H1, 1)) + " / tpPrice = " + string(orders[i].tpPrice));
	                OrderClose(orders[i].ticket, OrderLots(), MarketInfo(orders[i].symbol, MODE_BID), 3, Red);
	                
	             } else
	             {
	             	 WriteLog(LogFileHandle, "---Close order. hClose1 = " + string(iClose(orders[i].symbol, PERIOD_H1, 1)) + " / tpPrice = " + string(orders[i].tpPrice));
	                OrderClose(orders[i].ticket, OrderLots(), MarketInfo(orders[i].symbol, MODE_ASK), 3, Red);
	             }
	             
	       }
	  }
	}
      
      void sendOrder(order & iOrder)
      {     
         double   cPrice;                      //current price    
         double   cLotSize   = 0;                //current lot size
         double   cDeposit   = AccountEquity();
         double   cTickSize  = MarketInfo(iOrder.symbol, MODE_TICKSIZE);
         int      cDigits    = (int)MarketInfo(iOrder.symbol, MODE_DIGITS);
         
         int      orderTicket = 0;
         
         //WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) + ", type = " + string(iOrder.type));
         
         if(iOrder.type == "sell"
            || iOrder.type == "buy")
         {
            if(fixLotSize)
            {
               
               cLotSize = lotSize;
               
            } else
            {
               cLotSize = GetQuantity(MathAbs(iOrder.enPrice - iOrder.slPrice) / cTickSize, cDeposit, riskPerTrade, cDigits, iOrder.symbol);
            }
         }
         
         //if buy
         if(iOrder.type == "buy")
         {
            //Get last ask
            cPrice = MarketInfo(iOrder.symbol, MODE_ASK);
            
            //WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) + ", enPrice = " + string(iOrder.enPrice) + ", cPrice = " + string(cPrice));
            
            //BuyStop
            if(iOrder.enPrice > cPrice)
            {  
            	/*             
               WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) +
                  ", cLotSize = " + string(cLotSize) +
                  ", enPrice = " + string(iOrder.enPrice) +
                  ", slPrice = " + string(iOrder.slPrice) +
                  ", tpPrice = " + string(iOrder.tpPrice));
                  */
               orderTicket = OrderSend(iOrder.symbol, OP_BUYSTOP, cLotSize, iOrder.enPrice, 3, iOrder.slPrice, iOrder.tpPrice, "24fx v" + version + "/" + TimeToString(iOrder.cancelTime, TIME_MINUTES), magicNumber, iOrder.cancelTime, Green);
               
               //WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) + ", orderTicket = " + string(orderTicket) + ", Error = " + string(GetLastError()));
                  
               if(orderTicket > 0
                  && orderTicket != iOrder.ticket)
               {
                  iOrder.ticket = orderTicket;
                  iOrder.processed = true;
               }
               
            } else
            //BuyLimit            
            if(iOrder.enPrice < cPrice)
            {
            	/*
               WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) +
                  ", cLotSize = " + string(cLotSize) +
                  ", enPrice = " + string(iOrder.enPrice) +
                  ", slPrice = " + string(iOrder.slPrice) +
                  ", tpPrice = " + string(iOrder.tpPrice));
               */
               orderTicket = OrderSend(iOrder.symbol, OP_BUYLIMIT, cLotSize, iOrder.enPrice, 3, iOrder.slPrice, iOrder.tpPrice, "24fx v" + version + "/" + TimeToString(iOrder.cancelTime, TIME_MINUTES), magicNumber, iOrder.cancelTime, Green);
               
               WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) + ", orderTicket = " + string(orderTicket) + ", Error = " + string(GetLastError()));
               
               if(orderTicket > 0
                  && orderTicket != iOrder.ticket)
               {
                  iOrder.ticket = orderTicket;
                  iOrder.processed = true;
               }
            }
            
         }
         
         //if sell
         if(iOrder.type == "sell")
         {
            //Get last bid
            cPrice = MarketInfo(iOrder.symbol, MODE_BID);
            
            //WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) + ", enPrice = " + string(iOrder.enPrice) + ", cPrice = " + string(cPrice));
            
            //Sell limit
            if(iOrder.enPrice > cPrice)
            {
            	/*
               WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) +
                  ", cLotSize = " + string(cLotSize) +
                  ", enPrice = " + string(iOrder.enPrice) +
                  ", slPrice = " + string(iOrder.slPrice) +
                  ", tpPrice = " + string(iOrder.tpPrice));
				*/
               orderTicket = OrderSend(iOrder.symbol, OP_SELLLIMIT, cLotSize, iOrder.enPrice, 3, iOrder.slPrice, iOrder.tpPrice, "24fx v" + version + "/" + TimeToString(iOrder.cancelTime, TIME_MINUTES), magicNumber, iOrder.cancelTime, Red);
               
               WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) + ", orderTicket = " + string(orderTicket) + ", Error = " + string(GetLastError()));
                              
               if(orderTicket > 0
                  && orderTicket != iOrder.ticket)
               {
                  iOrder.ticket = orderTicket;
                  iOrder.processed = true;
               }
               
            } else
            //Sell stop            
            if(iOrder.enPrice < cPrice)
            {
            	/*
               WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) +
                  ", cLotSize = " + string(cLotSize) +
                  ", enPrice = " + string(iOrder.enPrice) +
                  ", slPrice = " + string(iOrder.slPrice) +
                  ", tpPrice = " + string(iOrder.tpPrice));
				*/
               orderTicket = OrderSend(iOrder.symbol, OP_SELLSTOP, cLotSize, iOrder.enPrice, 3, iOrder.slPrice, iOrder.tpPrice, "24fx v" + version + "/" + TimeToString(iOrder.cancelTime, TIME_MINUTES), magicNumber, iOrder.cancelTime, Red);
                
                WriteLog(LogFileHandle, "---sendOrder. Symbol = " + string(iOrder.symbol) + ", orderTicket = " + string(orderTicket) + ", Error = " + string(GetLastError()));
                
               if(orderTicket > 0
                  && orderTicket != iOrder.ticket)
               {
                  iOrder.ticket = orderTicket;
                  iOrder.processed = true;
               }

            }
         
         }
      }
};

clOrderManager orderManager();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
	string workHoursArrayStr[];
   string workHoursStr;
   
   workHoursStr = _workHours;
    
   	//��������� �� ��������� ������ � �������� ������ ������ workHours
   	//������ �������
   StringReplace(workHoursStr, " ", "");
	splitString(workHoursStr, ",", workHoursArrayStr);
	
	ArrayResize(workHours, ArraySize(workHoursArrayStr));
	
	//��������� ��������� ������ � ��������, ��� �������� �������������
	for(int i = 0; i < ArraySize(workHoursArrayStr); i++)
	{
		workHours[i] = StrToInteger(workHoursArrayStr[i]);
	}
   
   orderManager.initialize(_lotSize, _magicNumber, _fixLotSize, _riskPerTrade, workHours);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   FileClose(LogFileHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{   
   //���� ���������� ����� �������, �� ����� ������ ����, ��� ����� ��� ����� ��������� �� ����
   if(LogFileHandle == 0)
   {
      string currentTimeStr = TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      
      StringReplace(currentTimeStr, ".", "");
      StringReplace(currentTimeStr, ":", "");
      StringReplace(currentTimeStr, " ", "_");
      
      LogFileHandle = FileOpen("24fx\\" +"log_" + currentTimeStr + ".txt", FILE_WRITE);
      WriteLog(LogFileHandle, "---File opened (#0001)");
   }

   
   //Get data each dataUpdateInterval minutes
   if(!lastDataLoadTime
      || TimeCurrent() - lastDataLoadTime >= _dataUpdateInterval * 60)
   {
      Print(IntegerToString(_dataUpdateInterval) + " left...");
      getData();
      lastDataLoadTime = TimeCurrent();
   }
   
   orderManager.sendOrders();
   
}

void WriteLog(int FileHandle, string LogString)
{
   FileWrite(FileHandle, TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + ": " + LogString);   
}


//+------------------------------------------------------------------+

void getData()
{
   int         res;
   string      fileName             = "output.html";
   string      fileName2            = "output2.html";
   //string url = "http://dzam.myjino.ru/test/test.php";
   string      url                  = "http://24fx.ru/cabinet/";
   string      user                 = "USERNAME";
   string      pass                 = "PASS";
   string      authLoginStr         = "auth_login";                              //������ � ������ ���� �����������. �� ��� ����� ��������� ����� �� � ������� ��� ���.
   string      authStr              ="auth_login=" + user + "&auth_password=" + pass;
   
   string      headers;
   int         timeOut              = 10000;
   char        post[],result[];
   
   string      str;
   int         firstPosRead;
   int         lastPosRead;
   string      enterString          = "<th>�������</th></tr><tr><td>";  //������ ������ �������
   string      exitString           = "</tr></table></div>";            //������ ��������� �������
   string      clearStrings[4];                                         //������ ����� ��� ��������
   
   string      splitElement         = "</td>";                          //������ ����������� ����� �������
   
   string      dirName              = "24fx";                           //������� ��� �����
   
   int         index                = 0;                                //������. ������������ ��� ������
   
   //������ �� ��������
   clearStrings[0] = " style=\"text-align:left;padding-left:10px;\"";
   clearStrings[1] = " style=\" \"";
   clearStrings[2] = "</tr><tr>";
   clearStrings[3] = "<td>";
   
   //���� ���� ����, �� ���� POST ������, ����� GET
   if(cookie == "")
   {
      StringToCharArray(authStr, post, 0, StringLen(authStr));
      res = WebRequest("POST", url, "", NULL, timeOut, post, ArraySize(post), result, headers);
      
      WriteLog(LogFileHandle, "---POST res " + res);
      
      //�������� ����
      if(res != -1)
      {
         index = StringFind(headers, "PHPSESSID=");
         //���� ����� ������ � ������
         if(index > 0)
         {
            cookie = StringSubstr(headers, index, StringFind(headers, ";", index) - index + 1);
            //Print(cookie);
         }
      }
   
   } else   
   {
      //Get data
      res = WebRequest("GET", url, cookie, NULL, timeOut, post, 0, result, headers);
      WriteLog(LogFileHandle, "---GET res " + res);
   }
   
   if(res == -1)
   {
      Print("������ � WebRequest. ��� ������  =",GetLastError());
      
      //Print(kernel32::GetLastError());
      
      //--- ��������, URL ����������� � ������, ������� ��������� � ������������� ��� ����������
      //MessageBox("���������� �������� ����� '"+url+"' � ������ ����������� URL �� ������� '���������'","������",MB_ICONINFORMATION);
      
      
      cookie = "";
      return;      
   }
   else
   {
      str = CharArrayToString(result, 0);
      if(_writeToTestFile)
      {
         writeDataToFile(dirName, fileName, str);
      }

      //���� ����� ������� � ������ ����������:
      //1. ����� ���� ���� �������
      //1.1. �� ������ ����������������. � ���� ������ ��� ����, ����� ���� ������
      //1.2. �� �� ������ ����������������. ����� � ����� �� ������� �������� �����������. ������� ��������� � ����� ��������� ��������

      //2. ����� ���� �� ���� �������
      //2.1. �� ������ �������� �������� � ��������. � ���� ������ ��� ���� � ����� ���� ������
      //2.2. �� �������� �������� �����������. � ���� ������ ���������� ��������� POST ������. ������� ���� � ������ ��������� ��� �� ��������� ��������
      index = StringFind(str, authLoginStr);          

      if(index > 0)
      {
         Print("�� ������� ������� �����������!");
         cookie = "";
         return;
      }

      
      StringReplace(str, "\n", "");
      //writeDataToFile(dirName, fileName2, str);
      
      //Seek enter string
      firstPosRead = StringFind(str, enterString, 0);
      lastPosRead = StringFind(str, exitString, firstPosRead);
      
      if(firstPosRead == -1)
      {
         Print("Enter string not find!");
         return;
      }
      
      if(lastPosRead == -1)
      {
         Print("Exit string not find!");
         return;
      }

      tableString = StringSubstr(str, firstPosRead + StringLen(enterString) - 4, lastPosRead - firstPosRead - StringLen(exitString) - StringLen(enterString) - 4 - 1);
      tableString = clearStr(tableString, clearStrings);
      
      splitString(tableString, splitElement, tableStrings);
      
      fillOrdersArray();
   }
}

string clearStr(string inString, string & clStrings[])
{
   string result = inString;
   
   for(int i = 0; i < ArraySize(clStrings); i++)
   {
      StringReplace(result, clStrings[i], "");
   }
   
   return result;
}

void splitString(string inString, string splitString, string & resString[])
{
   //Separator char
   string splitSymbol = "#";
   ushort splitChar;
   
   splitChar = StringGetCharacter(splitSymbol, 0);
   
   //Let replace our splitString with symbol #
   StringReplace(inString, splitString, "#");
   StringSplit(inString, splitChar, resString);
}

//For print all elements of array
void printArray(string  & stringArray[])
{
   for(int i = 0; i < ArraySize(stringArray); i++)
   {
      Print("el " + string(i) + " = " + stringArray[i]);
   }
}

void writeDataToFile(string dirName, string fileName, string data)
{
   int file_handle=FileOpen(dirName+"//"+fileName, FILE_WRITE);
   if(file_handle!=INVALID_HANDLE)
     {
      FileWrite(file_handle, data);

      //--- ��������� ����
      FileClose(file_handle);
     }
}

void fillOrdersArray()
{

   int columnsInTable = 8; //Columns count in orders table
   int ordersCount = (int)((ArraySize(tableStrings) + 1)/ columnsInTable);
   
   order newOrder;
   
   for(int i = 0; i < ArraySize(tableStrings); i = i + columnsInTable)
   {
      newOrder.openTime    = formatToTime(tableStrings[i]) + _timeShift * 60 * 60;
      newOrder.cancelTime  = formatToTime(tableStrings[i + 1])  + _timeShift * 60 * 60;
      newOrder.symbol      = formatToSymbol(tableStrings[i + 2]) + _symbolPostfix;
      newOrder.type        = formatToOrderType(tableStrings[i + 2]);
      newOrder.enPrice     = StrToDouble(tableStrings[i + 3]);
      newOrder.tpPrice     = StrToDouble(tableStrings[i + 4]);
      newOrder.slPrice     = StrToDouble(tableStrings[i + 5]);

      orderManager.updateData(newOrder);
   }
}   


datetime formatToTime(string inData)
{
   datetime res;
   inData = StringSubstr(inData,0, StringLen(inData) - 3);
   
   StringReplace(inData, "-", ".");
   
   res = StrToTime(inData);
   
   return res;
}

string formatToOrderType(string inData)
{
   string   res;
   int      index;
   
   index = StringFind(inData, "�������");
   
   if(index == -1)
   {
      
      res = "buy";
      
   } else
   {
      res = "sell";
   }
   
   return res;
}

string formatToSymbol(string inData)
{
   string res;
   
   StringReplace(inData, "/", "");
   res = StringSubstr(inData, 0, 6); 
   
   return res;
}

bool arraySearch(int &inArray[], int value)
{
   bool result = false;
   for(int i = 0; i < ArraySize(inArray); i++)
   {
      if(inArray[i] == value)
      {
         result = true;
         return result;
      }
   }
   
   return result;
}