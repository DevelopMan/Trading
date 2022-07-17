--V.1.1.

Settings= {
	Name = "ATR_Channel",	
	CandlesCount		= 4,
	line =
	{
		{
			Name	= "Up34ATR",
			Color	= RGB(170, 255, 170),
			Type	= TYPE_LINE,
			Width	= 1
		},
		{
			Name	= "Down34ATR1",
			Color	= RGB(255, 170, 170),
			Type	= TYPE_LINE,
			Width	= 1
		},
		{
			Name	= "UpATR",
			Color	= RGB(0, 150, 0),
			Type	= TYPE_LINE,
			Width	= 1
		},
		{
			Name	= "DownATR",
			Color	= RGB(255, 100, 100),
			Type	= TYPE_LINE,
			Width	= 1
		}
	}
}

function AddBarToArray(ArrayElement)
	
	table.insert(BarSizes, ArrayElement)
	table.remove(BarSizes, 1)
		
	return 1
	
end

function SetATR()
	local ATR = 0;
	local ATR34 = 0;		
	
	--PrintArray(BarSizes)
	
	--Считаем среднюю во всем массиве
	for i = 1, #BarSizes do
		ATR = ATR + BarSizes[i]
	end
	
	ATR = (ATR / #BarSizes)
	ATR34 = ATR * 3 / 4
	
	UpATR	= ClosePrice + ATR
	DownATR = ClosePrice - ATR
	
	Up34ATR		= ClosePrice + ATR34
	Down34ATR	= ClosePrice - ATR34
	
	--message(tostring(UpATR).." / "..tostring(DownATR), 1)
	--message(tostring(Up34ATR).." / "..tostring(Down34ATR), 1)
	--message(tostring(#BarSizes), 1)
end

function PrintArray(Array)
	local ArrayStr = ""
	
	for i = 1, #Array do
		ArrayStr = ArrayStr..","..Array[i]
	end
	
	message(ArrayStr, 1)
end

function TransferDay(index)

	--Так это последняя свеча дня, установим цену закрытия, от которой будет откладывать ATR
	ClosePrice = C(index - 1)
	
	-- если мы набрали достаточно баров для расчета средней
	if CalcDays == Settings.CandlesCount then
		
		AddBarToArray(High - Low)
		
		SetATR()
		
	else
		table.insert(BarSizes, High - Low)
		CalcDays = CalcDays + 1
	end
	
	--message(tostring(ClosePrice))
	--PrintArray(BarSizes)	
	--message(tostring(CurrentDay).."/"..tostring(CurrentMonth).."/"..tostring(CurrentYear),1)
	--message(tostring(High).."/"..tostring(Low), 1)	
	
	--Установим текущую дату
	CurrentDay		= T(index).day
	CurrentMonth	= T(index).month
	CurrentYear		= T(index).year
	
	--PrintArray(BarSizes)
	return 1
end
	
function Init()
	--Инициализируем переменные.
	CurrentDay		= 0		--Текущий рассчетный день	
	CurrentMonth	= 0		--Текущий рассчетный меясц
	CurrentYear		= 0		--Текущий рассчетный год	
	
	BarSizes		= {}	--Размеры дневных баров.	
	CalcDays		= 0		--Количество рассчитанных дней	
	ClosePrice		= 0		--Цена закрытия предыдущего дня
	High			= 0		--High текущего дня
	Low				= 0		--Дщц текущего дня
	
	UpATR			= nil	--Верхняя граница АТР
	DownATR			= nil	--Нижняя граница АТР
	
	Up34ATR			= nil	--Верхняя граница 3/4 АТР
	Down34ATR		= nil	--Нижняя граница 3/4 АТР

	--BarsInChart		= getNumCandles(Settings.ChartID) --Количество свечей, необходимо, чтобы пропустить первые Settings.CandelsCount
	
	return 2
end

function OnCalculate(index)
	
	local DayOfCurrentBar	= T(index).day
	local MonthOfCurrentBar = T(index).month
	local YearOfCurrentBar	= T(index).year
		
	--Если текущий расченый день равен 0, то присвоимему текущее число
	if CurrentDay == 0 then
		CurrentDay = T(index).day
	end
	
	--Если текущий расченый месяц равен 0, то присвоимему текущее число
	if CurrentMonth == 0 then
		CurrentMonth = T(index).month
	end

	--Если текущий расченый год равен 0, то присвоимему текущее число
	if CurrentYear == 0 then
		CurrentYear = T(index).year
	end

	if High == 0 then		
		High = H(index)				
	end
	
	if Low == 0 then		
		Low = L(index)		
	end
	
	--Если это новый день, тогда вызовем процедуру обработки перехода на новый день
	if tostring(DayOfCurrentBar)..tostring(MonthOfCurrentBar)..tostring(YearOfCurrentBar) ~= 
		tostring(CurrentDay)..tostring(CurrentMonth)..tostring(CurrentYear) then
		
		TransferDay(index)
		
		High = H(index)		
		Low = L(index)

	end
	
	if H(index) > High then		
		High = H(index)		
	end
	
	if L(index) < Low then		
		Low = L(index)
	end

	return Up34ATR, Down34ATR, UpATR, DownATR
	--return H(index) + 20, L(index)-20
end
