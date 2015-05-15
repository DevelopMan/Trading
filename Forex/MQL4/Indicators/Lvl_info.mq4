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

static string  LvlName        = "#Lvl#";           //Имя объекта линии уровня

static string  SLName         = "#SL";             //Имя объекта линии стоп
static string  PName          = "#P";              //Имя объекта линии цены открытия
static string  TPName         = "#TP";             //Имя объекта линии профита

static string  SL2Name         = "#SL2#";          //Имя объекта линии расстояния 2 стопа

static string  SpreadUpName   = "#SpreadUp#";      //Имя объекта линии спреда выше графика
static string  SpreadDownName = "#SpreadDown#";    //Имя объекта линии спреда ниже графика

static string  LastTimeName   = "#LastTimeName#";  //Имя объекта надписи, сколько времени осталось до конца бара

//Для ATR
static string  ATRName        = "#ATR#";           //Имя объекта надписи, ATR
static string  ATR34Name      = "#ATR34#";         //Имя объекта надписи, 3/4 ATR
extern int     CalcBars       = 7;                 //Количество баров для расчета среднестатистического ATR
extern double  MaxDiff        = 100;               //Максимальная разница в пунктах между сравниваемыми барами.

extern bool    FixStopSize    = false;             //Фиксированный размер стопа, если false, то будет считаться от ATR
extern double  StopSize       = 100;               //Размер стопа в пунктах
extern double  PercATRTrend   = 10;                //Размер стопа в процентах от ATR если сделка по тренду
extern double  PercATRCTrend  = 5;                 //Размер стопа в процентах от ATR если сделка против тренда
extern double  BackLash       = 20;                //Размер люфта в процентах от стопа
extern int     PR             = 3;                 //Отношение Профит/Рск

extern bool    MoveLvl        = false;             //Двигать ли линию уровня
extern bool    ShowSpread     = false;             //Показывать линии спреда

extern string  Separator1     = "------------------------------";

extern bool    ShowKeyLevels  = false;             //Ключевые уровни



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
static int     BarsInCurrentDay; //Количество баров на текущем ТФ в текущем дне
static int     CurrDay;          //Номер текущего дня. Для расчета дневных переменных только при смене дня
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
//----
   //Ищем максимум текущего дня
   SetHiLow(0);
   
   //Инициализируем объекты
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
   
   //Считаем количество баров в текущем дне
   BarsInCurrentDay = GetBarsInCurrentDay();
   
   //Print(BarsInCurrentDay);
   
   //Рисуем линию двух стопов
   Set2StopLines();
   
   //Считаем ATR и 3/4ATR
   // Если это необходимо. Если наступил новый день
   if(CurrDay == 0 || CurrDay != TimeDay(TimeCurrent()))
   {
      CalcATR();
      CurrDay = TimeDay(TimeCurrent());
   }
   
   //Определим тренд
   CheckTrend();
   
   //Инициируем минимумы и максимумы
   SetHiLow(0);
   //SetHiLow(1);
   //SetHiLow(2);
   
   //Двигаем Hi/Low линии
   MoveHiLowLines();
   
   //Считаем ATR текущего дня
   CurATR = (HiArray[0] - LowArray[0]) / Point;
   //Print(HiArray[0] + " " + LowArray[0] + " " + CurATR);
   
   //Считаем количество баров на экране
   BarsPerChart = WindowBarsPerChart();
   
   //Считаем сколько секунд до конца свечи
   GetEndTime();
   //Print(EndTimeM + " " + EndTimeS);
   
   if(MoveLvl == true)
   {
      //Двигаем уровень
      MoveLvlLine();
      //Двигаем стоп, профит
      MoveSLTPLines();
   }

   
   
   if(ShowSpread == true)
   {
      //Двигаем спреды
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
   
   //Заполним даты минимального бара и максимального
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
   //Инициализируем переменные
   string GDirection, LDirection, ATRDirection;
   
   //Получим направление
   GDirection     = ObjectDescription(GTrendName);
   LDirection     = ObjectDescription(LTrendName);
   ATRDirection   = ObjectDescription(ATRTrendName);
   
   //Если направление вверх
   if((GDirection == "Up" && LDirection == "Up" && (ATRDirection == "Up" || ATRDirection == "-"))
      || (GDirection == "Up" && LDirection == "Down" && ATRDirection == "Up"))
   {
      //Вызовем процедуру установки на покупку
      SetLinesBuy();
   } else if((GDirection == "Down" && LDirection == "Down" && (ATRDirection == "Down" || ATRDirection == "-"))
      || (GDirection == "Down" && LDirection == "Up" && ATRDirection == "Down"))
   {
      //Вызовем процедуру установки на продажу      
      SetLinesSell();
   }
}

void SetLinesBuy()
{
   //Инициализируем переменные
   double PriceLvl, StopLvl, OpenPrice, TPLvl, RealStopSize;
   
   //Получаем значение цены уровеня
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
   
   //Если такой линии нет, то ничего не делаем
   if(PriceLvl <= 0)
   {
      return(0);
   }
   
   //Устанавливаем лнию стопа
   ObjectSet(SLName, OBJPROP_PRICE1, StopLvl);
   
   //Устанавливаем линию покупки
   ObjectSet(PName, OBJPROP_PRICE1, OpenPrice);
   
   //Устанавливаем линию профита
   ObjectSet(TPName, OBJPROP_PRICE1, TPLvl);
}

void SetLinesSell()
{
   //Инициализируем переменные
   double PriceLvl, StopLvl, OpenPrice, TPLvl, RealStopSize;
   
   //Получаем значение цены уровеня
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
   
   //Если такой линии нет, то ничего не делаем
   if(PriceLvl <= 0)
   {
      return(0);
   }
   
   //Устанавливаем лнию стопа
   ObjectSet(SLName, OBJPROP_PRICE1, StopLvl);
   
   //Устанавливаем линию покупки
   ObjectSet(PName, OBJPROP_PRICE1, OpenPrice);
   
   //Устанавливаем линию профита
   ObjectSet(TPName, OBJPROP_PRICE1, TPLvl);
}

void InitializeObjects()
{
   int ObjIndex;
   
   //-------------------------------
   // Инициализируем линии
   //-------------------------------
   
   //Уровень
   ObjectCreate(LvlName, OBJ_HLINE, 0, 0, Ask);
   ObjectSet(LvlName, OBJPROP_STYLE, 0);
   ObjectSet(LvlName, OBJPROP_COLOR, C'128,0,128');
   
   //Цена открытия
   ObjectCreate(PName, OBJ_HLINE, 0, 0, Ask);
   ObjectSet(PName, OBJPROP_STYLE, 4);
   ObjectSet(PName, OBJPROP_COLOR, White);
   
   //Стоп
   ObjectCreate(SLName, OBJ_HLINE, 0, 0, Ask);
   ObjectSet(SLName, OBJPROP_STYLE, 1);
   ObjectSet(SLName, OBJPROP_COLOR, C'255,192,203');
   
   //Тейк
   ObjectCreate(TPName, OBJ_HLINE, 0, 0, Ask);
   ObjectSet(TPName, OBJPROP_STYLE, 1);
   ObjectSet(TPName, OBJPROP_COLOR, C'0,128,0');
      
   //-------------------------------
   // Время до окончания свечи
   //-------------------------------
   InitializeLabelObject(LastTimeName + "Caption", 10, 40, White, "Время до...:");
   InitializeLabelObject(LastTimeName, 90, 40, Red, "-");   
   
   //-------------------------------
   // Тренды
   //-------------------------------
   InitializeLabelObject(GTrendName + "Caption", 10, 60, White, "г. тренд:");
   InitializeLabelObject(GTrendName, 90, 60, Red, "-");
   
   InitializeLabelObject(LTrendName + "Caption", 10, 82, White, "л. тренд:");
   InitializeLabelObject(LTrendName, 90, 82, Red, "-");
   
   InitializeLabelObject(ATRTrendName + "Caption", 10, 104, White, "ATR тренд:");
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
   // Линии спреда
   //-------------------------------
   if(ShowSpread == true)
   {
      ObjIndex = ObjectFind(SpreadUpName);

      //Если не нашли объект, то создаем его
      if(ObjIndex == -1)
      {
         ObjectCreate(SpreadUpName, OBJ_HLINE, 0, 0, Ask + MarketInfo(Symbol(),MODE_SPREAD) * Point);
      }

      ObjIndex = ObjectFind(SpreadDownName);

      //Если не нашли объект, то создаем его
      if(ObjIndex == -1)
      {
         ObjectCreate(SpreadDownName, OBJ_HLINE, 0, 0, Bid - MarketInfo(Symbol(),MODE_SPREAD) * Point);
      }
   } else
   {
      //Удалим имеющиеся линии
      ObjectDelete(SpreadUpName);
      ObjectDelete(SpreadDownName);
   }
}

void InitializeLabelObject(string ObjName, double ObjX, double ObjY, color ObjColor, string Text)
{
   int ObjIndex;
   
   ObjIndex = ObjectFind(ObjName);
   //Если не нашли объект, то создаем его
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
   
   //Определим направление
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
   //Инициализируем переменные
   double   iBarSize, jBarSize;  //Размеры текущегих бара
   double   SameBarsCount;       //Количество баров с одинаковым размером
   double   MaxBar;              //Максимальное количество баров
   double   SumBarSize;          //Размер среднестатистического бара
   double   SumBarsCol;          //Количество максимальных баров
            
   //int    counted_bars=IndicatorCounted();
   
   MaxBar      = 0;
   SumBarSize  = 0;
   SumBarsCol  = 0;
   
   //Перебираем бары
   for(int i = 1; i <= CalcBars + 1; i++)
   {
      //Обсчитываем i-ый бар
      iBarSize = (iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i)) / Point;
      
      //Обнуляем похожих счетчик баров
      SameBarsCount = 1;
         
      //Сравниваем i бар с соседями
      for(int j = 1; j <= CalcBars; j++)
      {
         //... с самим с собой не сравниваем
         if(j != i)
         {
               
            jBarSize = (iHigh(NULL, PERIOD_D1, j) - iLow(NULL, PERIOD_D1, j)) / Point;
            //Если сравниваемый бар в диапазоне с текщим, то учитываем его.
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
   
   //Установим текст у объектов
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
   //Инициализируем переменные
   double MACD1, MACD2,         
         CP2,  //Цена закрытия позавчера
         CP;   //Текущая цена
   
   //CP1 = iClose(NULL, PERIOD_D1, 1);
   CP2 = iClose(NULL, PERIOD_D1, 2);
   CP  = Close[0];
   
   //Print(HiArray[0] + " " + LowArray[0] + " " + ATR34 * Point);
   //Если разница между минимумом и максимумом больше или равна 3/4 ATR, то анализируем направление исходя из ATR
   if((HiArray[0] - LowArray[0]) >= ATR34 * Point)
   {
      //ObjectSetText(GTrendName, "-");
      
      //Если ближе минимум, то
      if(MinIndBar < MaxIndBar)
      {
         //Проверяем расстояние от минимума до текщей цены
         // Если оно больше или равна 3/4ATR, то тренд "вниз"
         if((Close[0] - LowArray[0]) >= ATR34 * Point)
         {         
            ObjectSetText(ATRTrendName, "Down");
            //Прерываем проверку
            //return(0);
         } else // иначе в обратную сторону, так как прошли 3/4ATR
         {
            ObjectSetText(ATRTrendName, "Up");
            //Прерываем проверку
            //return(0);         
         }
      } else if(MaxIndBar < MinIndBar)
      {
      //Если ближе максимум, то
         //Проверяем растояние от максимума до текущей цены
         // Если она больше или равна 3/4ATR, то тренд "вверх"
         if((HiArray[0] - Close[0]) >= ATR34 * Point)
         {         
            ObjectSetText(ATRTrendName, "Up");
            //Прерываем проверку
            //return(0);
         } else // иначе в обратную сторону, так как прошли 3/4ATR
         {
            ObjectSetText(ATRTrendName, "Down");
            //Прерываем проверку
            //return(0);         
         }
         
      }     
   //Иначе направление тренда ATR = "-"
   } else
   {
      ObjectSetText(ATRTrendName, "-");
   }
   
   //Локальный тренд
   if(CP > CP2)
   {
      ObjectSetText(LTrendName, "Up");
   } else
   {
      ObjectSetText(LTrendName, "Down");
   }

  
  //Глобальный тренд
   MACD1 = iMACD(NULL, PERIOD_D1, 14, 26, 9, 0, 0, 1);
   MACD2 = iMACD(NULL, PERIOD_D1, 14, 26, 9, 0, 0, 2);

   //Если MACD1 больше MACD2 значит тренд восходящий,
   // если меньше, значит низходящий
   // если равны, то не торгуем
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
   datetime CurrentDay; //Текущий день
   datetime CalcDay;    //День для расчетного бара
   int i;
   
   i = 0;
   CurrentDay  = TimeDay(TimeCurrent());
   CalcDay     = TimeDay(iTime(NULL, 0, 0)); // День для текущего бара
   
   
   while(CalcDay == CurrentDay)
   {
      i++;
      CalcDay = TimeDay(iTime(NULL, 0, i)); // День для текущего бара      
   }
   
   return(i);
   
}

void Set2StopLines()
{
   //Инициализируем переменные
   int      ObjIndex;
   double   PPrice;   
   string   Direction;
   bool     IsLimit, IsS2;
   
   //Получим направление
   Direction = ObjectDescription(GTrendName);

   //Проверяем отрисована ли линия
   
   ObjIndex = ObjectFind(SL2Name);
   IsS2 = (ObjIndex != - 1);
   
   //Проверим есть ли открытые ордера по текущему инструменту
   //Перебираем все ордера
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      //Если это не отложенный ордер и совпадает с нашим инструментом
      if(OrderSymbol() == Symbol())
      {
         IsLimit = (OrderType() != OP_BUY) && (OrderType() != OP_SELL);
         
         
         if (IsLimit)
         {
            break;
         }
      }
      
   }
   
   //Если есть лимитник
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
      
   } else //если лимитников нет.   
   {
      //Ищем линию и если она отрисована, то удаляем ее
      ObjectDelete(SL2Name);      
   }
   
   
   //Если нет ни одного ордера, то удаляем линию 2 стопов
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