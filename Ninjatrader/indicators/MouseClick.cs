#region Using declarations
using System;
using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using NinjaTrader.Data;
using NinjaTrader.Gui.Chart;
using System.Windows.Forms;

#endregion

// This namespace holds all indicators and is required. Do not change it.
namespace NinjaTrader.Indicator
{
    [Description("Mouse click")]
    public class MouseClick : Indicator
    {
        #region Variables
        private ChartControl _chartControl;
        #endregion

        protected override void Initialize()
        {
        }

        private void ChartControl_MouseDown(object sender, MouseEventArgs e)
        {
            //Если кликнули без ALT, то ничего не делаем
            if ((Control.ModifierKeys & Keys.Alt) == 0)
            {
                return;
            }

            //Вычисляем бар, на котором рисовать вертикальную линию
            int first_bar_painted = ChartControl.FirstBarPainted;
            int last_bar_painted = ChartControl.LastBarPainted < Bars.Count ? ChartControl.LastBarPainted : Bars.Count - 1;
            double x_of_first_bar = ChartControl.GetXByBarIdx(Bars, first_bar_painted);
            
            double x_of_last_bar = ChartControl.GetXByBarIdx(BarsArray[0], last_bar_painted);
            
            double chart_width = x_of_last_bar - x_of_first_bar;
            int total_bars = last_bar_painted - first_bar_painted;

            int bar_index = (int)((e.X - 5) / (chart_width / total_bars));

            int bars_ago = total_bars - bar_index;

            string info_str = "Bar number = " + bar_index + "\n\r" +
                "High = " + High[bars_ago] + "\n\r" +
                "Low = " + Low[bars_ago] + "\n\r" +
                "Open = " + Open[bars_ago] + "\n\r" +
                "Close = " + Close[bars_ago] + "\n\r" +
                "Volume = " + Volume[bars_ago] + "\n\r";

            DrawTextFixed("BarInfo", info_str, TextPosition.BottomLeft);

            Print(Bars.Count.ToString() + " / " + last_bar_painted.ToString());

            DrawVerticalLine("V_Line", bars_ago, Color.Blue, DashStyle.Dash, 2);

            throw new NotImplementedException();
        }

        protected override void OnTermination()
        {
            if (_chartControl != null)
            {
                _chartControl.ChartPanel.MouseDown -= new MouseEventHandler(ChartControl_MouseDown);
            }
        }

        protected override void OnBarUpdate()
        {
            SetChartControl(this.ChartControl);
        }

        void SetChartControl(ChartControl control)
        {
            if (_chartControl == control)
                return;

            if (_chartControl != null)
            {
                _chartControl.ChartPanel.MouseDown -= new MouseEventHandler(ChartControl_MouseDown);
            }

            _chartControl = control;

            if (_chartControl != null)
            {
                _chartControl.ChartPanel.MouseDown += new MouseEventHandler(ChartControl_MouseDown);
            }
        }

    }
}