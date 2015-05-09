//+------------------------------------------------------------------+
//|                                                    Array_ext.mqh |
//|                                                             Dzam |
//|                                        https://www.stratozoo.com |
//+------------------------------------------------------------------+
#property copyright "Dzam"
#property link      "https://www.stratozoo.com"
#property strict

#include "ArrayDouble.mqh"

class CArrayDoubleExt : public CArrayDouble
{
   public:
      //Возвращает сумму всех элементов массива.
      double Summ()
      {
         double result = 0;
         
         for(int i = 0; i < m_data_total; i++)
         {
            result += m_data[i];
         }
         
         return result;
      }
      
      //Возвращает максимальное значение массива
      double MaxValue()
      {
         int index_of_max;
         
         index_of_max = Maximum(m_data_total - 1, 0);
         
         return At(index_of_max);
      }
      
      //Возвращает максимальное значение массива
      double MinValue()
      {
         int index_of_min;
         
         index_of_min = Minimum(m_data_total - 1, 0);
         
         return m_data[index_of_min];
      }
};