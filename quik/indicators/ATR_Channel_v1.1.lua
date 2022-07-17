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
	
	--������� ������� �� ���� �������
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

	--��� ��� ��������� ����� ���, ��������� ���� ��������, �� ������� ����� ����������� ATR
	ClosePrice = C(index - 1)
	
	-- ���� �� ������� ���������� ����� ��� ������� �������
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
	
	--��������� ������� ����
	CurrentDay		= T(index).day
	CurrentMonth	= T(index).month
	CurrentYear		= T(index).year
	
	--PrintArray(BarSizes)
	return 1
end
	
function Init()
	--�������������� ����������.
	CurrentDay		= 0		--������� ���������� ����	
	CurrentMonth	= 0		--������� ���������� �����
	CurrentYear		= 0		--������� ���������� ���	
	
	BarSizes		= {}	--������� ������� �����.	
	CalcDays		= 0		--���������� ������������ ����	
	ClosePrice		= 0		--���� �������� ����������� ���
	High			= 0		--High �������� ���
	Low				= 0		--��� �������� ���
	
	UpATR			= nil	--������� ������� ���
	DownATR			= nil	--������ ������� ���
	
	Up34ATR			= nil	--������� ������� 3/4 ���
	Down34ATR		= nil	--������ ������� 3/4 ���

	--BarsInChart		= getNumCandles(Settings.ChartID) --���������� ������, ����������, ����� ���������� ������ Settings.CandelsCount
	
	return 2
end

function OnCalculate(index)
	
	local DayOfCurrentBar	= T(index).day
	local MonthOfCurrentBar = T(index).month
	local YearOfCurrentBar	= T(index).year
		
	--���� ������� �������� ���� ����� 0, �� ����������� ������� �����
	if CurrentDay == 0 then
		CurrentDay = T(index).day
	end
	
	--���� ������� �������� ����� ����� 0, �� ����������� ������� �����
	if CurrentMonth == 0 then
		CurrentMonth = T(index).month
	end

	--���� ������� �������� ��� ����� 0, �� ����������� ������� �����
	if CurrentYear == 0 then
		CurrentYear = T(index).year
	end

	if High == 0 then		
		High = H(index)				
	end
	
	if Low == 0 then		
		Low = L(index)		
	end
	
	--���� ��� ����� ����, ����� ������� ��������� ��������� �������� �� ����� ����
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
