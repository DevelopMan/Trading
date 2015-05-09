//+------------------------------------------------------------------+
//|                                                         Test.mq4 |
//|                                                             Dzam |
//|                                         http://www.stratozoo.com |
//+------------------------------------------------------------------+
#property copyright "Dzam"
#property link      "http://www.stratozoo.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include "..\Include\Arrays\ArrayDouble_Ext.mqh"

void OnStart()
{
   CArrayDoubleExt arr;
   
   //Adding
   arr.Add(10);
   arr.Add(11);
   arr.Add(13);
   arr.Add(16);
   arr.Add(9);
   
   //Deleting
   arr.Delete(0); //Delete first element from the left
      
   
   printf("Size = %d, Max = %f, Min = %f, Summ = %f", arr.Total(), arr.MaxValue(), arr.MinValue(), arr.Summ());
}
//+------------------------------------------------------------------+
