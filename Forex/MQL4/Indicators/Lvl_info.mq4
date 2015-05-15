//+------------------------------------------------------------------+
//|                                                     Lvl_info.mq4 |
//|                                           Copyright 2014, DzamFX |
//|                                                           v.2.0. |
//|                                                       18.04.2014 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, DzamFX"
#property link      ""

#property indicator_chart_window
//--- input parameters
//extern string     Low1Name  =  "#Low1Lvl#";
//extern string     Hi1Name   =  "#Hi1lvl#";
//extern string     Low2Name  =  "#Low2Lvl#";
//extern string     Hi2Name   =  "#Hi2Lvl#";

static string  Low0Name       = "#Low0Lvl#";
static string  Hi0Name        = "#Hi0Lvl#";
static string  GTrendName     = "#GTrend#";
static string  LTrendName     = "#LTrend#";
static string  ATRTrendName   = "#ATRTrend#";
static string  PowerName      = "#ModelPowerName#";

static string  LvlName        = "#Lvl#";           //��� ������� ����� ������

static string  SLName         = "#SL";             //��� ������� ����� ����
static string  PName          = "#P";              //��� ������� ����� ���� ��������
static string  TPName         = "#TP";             //��� ������� ����� �������

static string  SL2Name         = "#SL2#";          //��� ������� ����� ���������� 2 �����

static string  SpreadUpName   = "#SpreadUp#";      //��� ������� ����� ������ ���� �������
static string  SpreadDownName = "#SpreadDown#";    //��� ������� ����� ������ ���� �������

static string  LastTimeName   = "#LastTimeName#";  //��� ������� �������, ������� ������� �������� �� ����� ����

//��� ATR
static string  ATRName        = "#ATR#";           //��� ������� �������, ATR
static string  ATR34Name      = "#ATR34#";         //��� ������� �������, 3/4 ATR
extern int     CalcBars       = 7;                 //���������� ����� ��� ������� ��������������������� ATR
extern double  MaxDiff        = 100;               //������������ ������� � ������� ����� ������������� ������.

extern bool    FixStopSize    = false;             //������������� ������ �����, ���� false, �� ����� ��������� �� ATR
extern double  StopSize       = 100;               //������ ����� � �������
extern double  PercATRTrend   = 10;                //������ ����� � ��������� �� ATR ���� ������ �� ������
extern double  PercATRCTrend  = 5;                 //������ ����� � ��������� �� ATR ���� ������ ������ ������
extern double  BackLash       = 20;                //������ ����� � ��������� �� �����
extern int     PR             = 3;                 //��������� ������/���

extern bool    MoveLvl        = false;             //������� �� ����� ������
extern bool    ShowSpread     = false;             //���������� ����� ������

extern string  Separator1     = "------------------------------";

extern bool    ShowKeyLevels  = false;             //�������� ������



static double  HiArray[3];
static double  LowArray[3];

static int  MaxIndBar;
static int  MinIndBar;

static double  CurATR;
static int     BarsPerChart;
static double  EndTimeM;
static double  EndTimeS;
static double  ATR;
static double  ATR34;
static int     BarsInCurrentDay; //���������� ����� �� ������� �� � ������� ���
static int     CurrDay;          //����� �������� ���. ��� ������� ������� ���������� ������ ��� ����� ���
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
//----
   //���� �������� �������� ���
   SetHiLow(0);
   
   //�������������� �������
   InitializeObjects();
   //SetHiLow(1);
   //SetHiLow(2);
   
   CurrDay = 0;
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
   
   //������� ���������� ����� � ������� ���
   BarsInCurrentDay = GetBarsInCurrentDay();
   
   //Print(BarsInCurrentDay);
   
   //������ ����� ���� ������
   Set2StopLines();
   
   //������� ATR � 3/4ATR
   // ���� ��� ����������. ���� �������� ����� ����
   if(CurrDay == 0 || CurrDay != TimeDay(TimeCurrent()))
   {
      CalcATR();
      CurrDay = TimeDay(TimeCurrent());
   }
   
   //��������� �����
   CheckTrend();
   
   //���������� �������� � ���������
   SetHiLow(0);
   //SetHiLow(1);
   //SetHiLow(2);
   
   //������� Hi/Low �����
   MoveHiLowLines();
   
   //������� ATR �������� ���
   CurATR = (HiArray[0] - LowArray[0]) / Point;
   //Print(HiArray[0] + " " + LowArray[0] + " " + CurATR);
   
   //������� ���������� ����� �� ������
   BarsPerChart = WindowBarsPerChart();
   
   //������� ������� ������ �� ����� �����
   GetEndTime();
   //Print(EndTimeM + " " + EndTimeS);
   
   if(MoveLvl == true)
   {
      //������� �������
      MoveLvlLine();
      //������� ����, ������
      MoveSLTPLines();
   }

   
   
   if(ShowSpread == true)
   {
      //������� ������
      MoveSpreads();   
   }

//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+

void SetHiLow(int Shift)
{   
   HiArray[Shift]    = iHigh(NULL, PERIOD_D1, Shift);
   LowArray[Shift]   = iLow(NULL, PERIOD_D1, Shift);
   
   //�������� ���� ������������ ���� � �������������
   MaxIndBar   = iHighest(NULL, 0, MODE_HIGH, BarsInCurrentDay, 0);
   MinIndBar   = iLowest(NULL, 0, MODE_LOW, BarsInCurrentDay, 0);
}

void GetEndTime()
{
	double i;
   int m;
   
   m = Time[0] + Period() * 60 - CurTime();
   
   i = m / 60.0;
   
   EndTimeS = m%60;
   
   m = (m - m % 60) / 60;
   
   EndTimeM = m;
   
   ObjectSetText(LastTimeName, DoubleToStr(EndTimeM, 0) + ":" + DoubleToStr(EndTimeS, 0), 10);
}

void MoveHiLowLines()
{
   //ObjectSet(Hi2Name, OBJPROP_PRICE1, HiArray[2]);
   //ObjectSet(Hi1Name, OBJPROP_PRICE1, HiArray[1]);
   ObjectSet(Hi0Name, OBJPROP_PRICE1, HiArray[0]);
   
   //ObjectSet(Low2Name, OBJPROP_PRICE1, LowArray[2]);
   //ObjectSet(Low1Name, OBJPROP_PRICE1, LowArray[1]);
   ObjectSet(Low0Name, OBJPROP_PRICE1, LowArray[0]);
}

void MoveSLTPLines()
{
   //�������������� ����������
   string GDirection, LDirection, ATRDirection;
   
   //������� �����������
   GDirection     = ObjectDescription(GTrendName);
   LDirection     = ObjectDescription(LTrendName);
   ATRDirection   = ObjectDescription(ATRTrendName);
   
   //���� ����������� �����
   if((GDirection == "Up" && LDirection == "Up" && (ATRDirection == "Up" || ATRDirection == "-"))
      || (GDirection == "Up" && LDirection == "Down" && ATRDirection == "Up"))
   {
      //������� ��������� ��������� �� �������
      SetLinesBuy();
   } else if((GDirection == "Down" && LDirection == "Down" && (ATRDirection == "Down" || ATRDirection == "-"))
      || (GDirection == "Down" && LDirection == "Up" && ATRDirection == "Down"))
   {
      //������� ��������� ��������� �� �������      
      SetLinesSell();
   }
}

void SetLinesBuy()
{
   //�������������� ����������
   double PriceLvl, StopLvl, OpenPrice, TPLvl, RealStopSize;
   
   //�������� �������� ���� �������
   PriceLvl = ObjectGet(LvlName, OBJPROP_PRICE1);
   
   if(FixStopSize == true)
   {
      RealStopSize = StopSize;
   } else
   {
      RealStopSize = GetStopSize();
   }
      
   OpenPrice   = PriceLvl + (RealStopSize / 100 * BackLash) * Point;
   StopLvl     = OpenPrice - RealStopSize * Point;   
   TPLvl       = OpenPrice + RealStopSize * PR * Point;
   
   //���� ����� ����� ���, �� ������ �� ������
   if(PriceLvl <= 0)
   {
      return(0);
   }
   
   //������������� ���� �����
   ObjectSet(SLName, OBJPROP_PRICE1, StopLvl);
   
   //������������� ����� �������
   ObjectSet(PName, OBJPROP_PRICE1, OpenPrice);
   
   //������������� ����� �������
   ObjectSet(TPName, OBJPROP_PRICE1, TPLvl);
}

void SetLinesSell()
{
   //�������������� ����������
   double PriceLvl, StopLvl, OpenPrice, TPLvl, RealStopSize;
   
   //�������� �������� ���� �������
   PriceLvl = ObjectGet(LvlName, OBJPROP_PRICE1);
   
   if(FixStopSize == true)
   {
      RealStopSize = StopSize;
   } else
   {
      RealStopSize = GetStopSize();
   }
   
   OpenPrice   = PriceLvl - (RealStopSize / 100 * BackLash) * Point;
   StopLvl     = OpenPrice + RealStopSize * Point;   
   TPLvl       = OpenPrice - RealStopSize * PR * Point;
   
   //���� ����� ����� ���, �� ������ �� ������
   if(PriceLvl <= 0)
   {
      return(0);
   }
   
   //������������� ���� �����
   ObjectSet(SLName, OBJPROP_PRICE1, StopLvl);
   
   //������������� ����� �������
   ObjectSet(PName, OBJPROP_PRICE1, OpenPrice);
   
   //������������� ����� �������
   ObjectSet(TPName, OBJPROP_PRICE1, TPLvl);
}

void InitializeObjects()
{
   int ObjIndex;
   
   //-------------------------------
   // �������������� �����
   //-------------------------------
   
   //�������
   ObjectCreate(LvlName, OBJ_HLINE, 0, 0, Ask);
   ObjectSet(LvlName, OBJPROP_STYLE, 0);
   ObjectSet(LvlName, OBJPROP_COLOR, C'128,0,128');
   
   //���� ��������
   ObjectCreate(PName, OBJ_HLINE, 0, 0, Ask);
   ObjectSet(PName, OBJPROP_STYLE, 4);
   ObjectSet(PName, OBJPROP_COLOR, White);
   
   //����
   ObjectCreate(SLName, OBJ_HLINE, 0, 0, Ask);
   ObjectSet(SLName, OBJPROP_STYLE, 1);
   ObjectSet(SLName, OBJPROP_COLOR, C'255,192,203');
   
   //����
   ObjectCreate(TPName, OBJ_HLINE, 0, 0, Ask);
   ObjectSet(TPName, OBJPROP_STYLE, 1);
   ObjectSet(TPName, OBJPROP_COLOR, C'0,128,0');
      
   //-------------------------------
   // ����� �� ��������� �����
   //-------------------------------
   InitializeLabelObject(LastTimeName + "Caption", 10, 40, White, "����� ��...:");
   InitializeLabelObject(LastTimeName, 90, 40, Red, "-");   
   
   //-------------------------------
   // ������
   //-------------------------------
   InitializeLabelObject(GTrendName + "Caption", 10, 60, White, "�. �����:");
   InitializeLabelObject(GTrendName, 90, 60, Red, "-");
   
   InitializeLabelObject(LTrendName + "Caption", 10, 82, White, "�. �����:");
   InitializeLabelObject(LTrendName, 90, 82, Red, "-");
   
   InitializeLabelObject(ATRTrendName + "Caption", 10, 104, White, "ATR �����:");
   InitializeLabelObject(ATRTrendName, 90, 104, Red, "-");
   
   //-------------------------------
   // ATR
   //-------------------------------
   InitializeLabelObject(ATRName + "Caption", 10, 126, White, "ATR:");
   InitializeLabelObject(ATRName, 90, 126, Red, "-");
   
   InitializeLabelObject(ATR34Name + "Caption", 10, 148, White, "3/4ATR:");
   InitializeLabelObject(ATR34Name, 90, 148, Red, "-");

   //-------------------------------
   // Power
   //-------------------------------
   InitializeLabelObject(PowerName + "Caption", 10, 170, White, "Power:");
   InitializeLabelObject(PowerName, 90, 170, Red, "-");

   //-------------------------------
   // ����� ������
   //-------------------------------
   if(ShowSpread == true)
   {
      ObjIndex = ObjectFind(SpreadUpName);

      //���� �� ����� ������, �� ������� ���
      if(ObjIndex == -1)
      {
         ObjectCreate(SpreadUpName, OBJ_HLINE, 0, 0, Ask + MarketInfo(Symbol(),MODE_SPREAD) * Point);
      }

      ObjIndex = ObjectFind(SpreadDownName);

      //���� �� ����� ������, �� ������� ���
      if(ObjIndex == -1)
      {
         ObjectCreate(SpreadDownName, OBJ_HLINE, 0, 0, Bid - MarketInfo(Symbol(),MODE_SPREAD) * Point);
      }
   } else
   {
      //������ ��������� �����
      ObjectDelete(SpreadUpName);
      ObjectDelete(SpreadDownName);
   }
}

void InitializeLabelObject(string ObjName, double ObjX, double ObjY, color ObjColor, string Text)
{
   int ObjIndex;
   
   ObjIndex = ObjectFind(ObjName);
   //���� �� ����� ������, �� ������� ���
   if(ObjIndex == -1)
   {
      ObjectCreate(ObjName, OBJ_LABEL, 0, 0, 0);
   }
   
   ObjectSet(ObjName, OBJPROP_CORNER, 0);
   ObjectSet(ObjName, OBJPROP_YDISTANCE, ObjY);
   ObjectSet(ObjName, OBJPROP_XDISTANCE, ObjX);
   ObjectSet(ObjName, OBJPROP_COLOR, ObjColor);
   
   ObjectSetText(ObjName, Text);
}

void MoveLvlLine()
{
   string GDirection, LDirection, ATRDirection;
   
   //��������� �����������
   GDirection     = ObjectDescription(GTrendName);
   LDirection     = ObjectDescription(LTrendName);
   ATRDirection   = ObjectDescription(ATRTrendName);
   
   if((GDirection == "Up" && LDirection == "Up" && ATRDirection == "-")
      || (GDirection == "Up" && LDirection == "Up" && ATRDirection == "Up")
      || (GDirection == "Up" && LDirection == "Down" && ATRDirection == "Up"))
   {
   
      ObjectSet(LvlName, OBJPROP_PRICE1, iLow(Symbol(), 0, 1));
      
   } else if((GDirection == "Down" && LDirection == "Down" && ATRDirection == "-")
      || (GDirection == "Down" && LDirection == "Down" && ATRDirection == "Down")
      || (GDirection == "Down" && LDirection == "Up" && ATRDirection == "Down"))
   {
   
      ObjectSet(LvlName, OBJPROP_PRICE1, iHigh(Symbol(), 0, 1));
      
   }
}

void MoveSpreads()
{
   ObjectSet(SpreadUpName, OBJPROP_PRICE1, Bid - MarketInfo(Symbol(),MODE_SPREAD) * Point);
   ObjectSet(SpreadDownName, OBJPROP_PRICE1, Ask + MarketInfo(Symbol(),MODE_SPREAD) * Point);   
    //- MarketInfo(Symbol(),MODE_SPREAD) * Point
}

void CalcATR()
{
   //�������������� ����������
   double   iBarSize, jBarSize;  //������� ��������� ����
   double   SameBarsCount;       //���������� ����� � ���������� ��������
   double   MaxBar;              //������������ ���������� �����
   double   SumBarSize;          //������ ��������������������� ����
   double   SumBarsCol;          //���������� ������������ �����
            
   //int    counted_bars=IndicatorCounted();
   
   MaxBar      = 0;
   SumBarSize  = 0;
   SumBarsCol  = 0;
   
   //���������� ����
   for(int i = 1; i <= CalcBars + 1; i++)
   {
      //����������� i-�� ���
      iBarSize = (iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i)) / Point;
      
      //�������� ������� ������� �����
      SameBarsCount = 1;
         
      //���������� i ��� � ��������
      for(int j = 1; j <= CalcBars; j++)
      {
         //... � ����� � ����� �� ����������
         if(j != i)
         {
               
            jBarSize = (iHigh(NULL, PERIOD_D1, j) - iLow(NULL, PERIOD_D1, j)) / Point;
            //���� ������������ ��� � ��������� � ������, �� ��������� ���.
            if(iBarSize + MaxDiff >= jBarSize && iBarSize - MaxDiff <= jBarSize)
            {
               SameBarsCount++;
            }
         }
      }
         
      if(MaxBar < SameBarsCount)
      {
         MaxBar      = SameBarsCount;
         
         SumBarsCol  = 1;
         SumBarSize  = iBarSize;
         
         //SumBarSize  = iBarSize;
      } else if(MaxBar == SameBarsCount)
      {
         SumBarsCol++;
         SumBarSize  = SumBarSize + iBarSize;
      }
   }
   
   //��������� ����� � ��������
   //if(SumBarsCol == 0)
   //{
   //   SumBarsCol = 1;
   //}
   //Print(SumBarSize);
   
   ATR   = SumBarSize/SumBarsCol;
   ATR34 = SumBarSize/SumBarsCol * 3 / 4;
   
   ObjectSetText(ATRName   , DoubleToStr(ATR, 0));
   ObjectSetText(ATR34Name , DoubleToStr(ATR34, 0));
   
   //ObjectSetText(ATRName, DoubleToStr(SumBarSize, 0));
   //ObjectSetText(ATR34Name, DoubleToStr(SumBarSize * 3 / 4, 0));
   return(0);
}

void CheckTrend()
{
   //�������������� ����������
   double MACD1, MACD2,         
         CP2,  //���� �������� ���������
         CP;   //������� ����
   
   //CP1 = iClose(NULL, PERIOD_D1, 1);
   CP2 = iClose(NULL, PERIOD_D1, 2);
   CP  = Close[0];
   
   //Print(HiArray[0] + " " + LowArray[0] + " " + ATR34 * Point);
   //���� ������� ����� ��������� � ���������� ������ ��� ����� 3/4 ATR, �� ����������� ����������� ������ �� ATR
   if((HiArray[0] - LowArray[0]) >= ATR34 * Point)
   {
      //ObjectSetText(GTrendName, "-");
      
      //���� ����� �������, ��
      if(MinIndBar < MaxIndBar)
      {
         //��������� ���������� �� �������� �� ������ ����
         // ���� ��� ������ ��� ����� 3/4ATR, �� ����� "����"
         if((Close[0] - LowArray[0]) >= ATR34 * Point)
         {         
            ObjectSetText(ATRTrendName, "Down");
            //��������� ��������
            //return(0);
         } else // ����� � �������� �������, ��� ��� ������ 3/4ATR
         {
            ObjectSetText(ATRTrendName, "Up");
            //��������� ��������
            //return(0);         
         }
      } else if(MaxIndBar < MinIndBar)
      {
      //���� ����� ��������, ��
         //��������� ��������� �� ��������� �� ������� ����
         // ���� ��� ������ ��� ����� 3/4ATR, �� ����� "�����"
         if((HiArray[0] - Close[0]) >= ATR34 * Point)
         {         
            ObjectSetText(ATRTrendName, "Up");
            //��������� ��������
            //return(0);
         } else // ����� � �������� �������, ��� ��� ������ 3/4ATR
         {
            ObjectSetText(ATRTrendName, "Down");
            //��������� ��������
            //return(0);         
         }
         
      }     
   //����� ����������� ������ ATR = "-"
   } else
   {
      ObjectSetText(ATRTrendName, "-");
   }
   
   //��������� �����
   if(CP > CP2)
   {
      ObjectSetText(LTrendName, "Up");
   } else
   {
      ObjectSetText(LTrendName, "Down");
   }

  
  //���������� �����
   MACD1 = iMACD(NULL, PERIOD_D1, 14, 26, 9, 0, 0, 1);
   MACD2 = iMACD(NULL, PERIOD_D1, 14, 26, 9, 0, 0, 2);

   //���� MACD1 ������ MACD2 ������ ����� ����������,
   // ���� ������, ������ ����������
   // ���� �����, �� �� �������
   if(MACD1 > MACD2)
   {
      ObjectSetText(GTrendName, "Up");
   } else if(MACD2 > MACD1)
   {
      ObjectSetText(GTrendName, "Down");
   } else
   {
      ObjectSetText(GTrendName, "----");
   }
}

int GetBarsInCurrentDay()
{
   datetime CurrentDay; //������� ����
   datetime CalcDay;    //���� ��� ���������� ����
   int i;
   
   i = 0;
   CurrentDay  = TimeDay(TimeCurrent());
   CalcDay     = TimeDay(iTime(NULL, 0, 0)); // ���� ��� �������� ����
   
   
   while(CalcDay == CurrentDay)
   {
      i++;
      CalcDay = TimeDay(iTime(NULL, 0, i)); // ���� ��� �������� ����      
   }
   
   return(i);
   
}

void Set2StopLines()
{
   //�������������� ����������
   int      ObjIndex;
   double   PPrice;   
   string   Direction;
   bool     IsLimit, IsS2;
   
   //������� �����������
   Direction = ObjectDescription(GTrendName);

   //��������� ���������� �� �����
   
   ObjIndex = ObjectFind(SL2Name);
   IsS2 = (ObjIndex != - 1);
   
   //�������� ���� �� �������� ������ �� �������� �����������
   //���������� ��� ������
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      //���� ��� �� ���������� ����� � ��������� � ����� ������������
      if(OrderSymbol() == Symbol())
      {
         IsLimit = (OrderType() != OP_BUY) && (OrderType() != OP_SELL);
         
         
         if (IsLimit)
         {
            break;
         }
      }
      
   }
   
   //���� ���� ��������
   if(IsLimit)
   {
      double RealStopSize;
      
      PPrice = ObjectGet(PName, OBJPROP_PRICE1);
      
      if(FixStopSize == true)
      {
         RealStopSize = StopSize;
      } else
      {
         RealStopSize = GetStopSize();
      }

      if(Direction == "Up")
      {
         ObjectCreate(SL2Name, OBJ_HLINE, 0, 0, PPrice + RealStopSize * 2 * Point);
      } else if(Direction == "Down")
      {
         ObjectCreate(SL2Name, OBJ_HLINE, 0, 0, PPrice - RealStopSize * 2 * Point);
      }
      
      ObjectSet(SL2Name, OBJPROP_COLOR, CornflowerBlue);
      
   } else //���� ���������� ���.   
   {
      //���� ����� � ���� ��� ����������, �� ������� ��
      ObjectDelete(SL2Name);      
   }
   
   
   //���� ��� �� ������ ������, �� ������� ����� 2 ������
   if(OrdersTotal() == 0)
   {
      ObjectDelete(SL2Name);
   }
}

double GetStopSize()
{
   string GDirection, LDirection, ATRDirection;
   
   GDirection     = ObjectDescription(GTrendName);
   LDirection     = ObjectDescription(LTrendName);
   ATRDirection   = ObjectDescription(ATRTrendName);
   
   if((GDirection == "Up" && LDirection == "Up" && (ATRDirection == "Up" || ATRDirection == "-"))      
      || (GDirection == "Down" && LDirection == "Down" && (ATRDirection == "Down" || ATRDirection == "-")))
   {
      
      return(ATR*PercATRTrend/100);
      
   } else if((GDirection == "Up" && LDirection == "Down" && ATRDirection == "Up")
      || (GDirection == "Down" && LDirection == "Up" && ATRDirection == "Down"))
   {
      
      return(ATR*PercATRCTrend/100);
      
   } else
   {
      return(0);
   }
}