/******************************************************************************************************/
/******************************************************************************************************/
/*INPUT VARIABLES*/
/******************************************************************************************************/
/******************************************************************************************************/
/*folder location of datasets*/
libname mylib "C:\Users\gelly\Desktop\Github\IndianTakeOut\Raw Data";
/*artificial working directory*/
libname temp "C:\Users\gelly\Documents\All Data\Temp";

/*indian takeout location 1*/
%let inputIndian1 = C:\Users\gelly\Desktop\Github\IndianTakeOut\Raw Data\Indian Food Takeout 1.csv;
/*indian takeout location 2*/
%let inputIndian2 = C:\Users\gelly\Desktop\Github\IndianTakeOut\Raw Data\Indian Food Takeout 2.csv;
/*weather data*/
%let inputWeather = C:\Users\gelly\Desktop\Github\IndianTakeOut\Raw Data\Weather Data.csv;

/******************************************************************************************************/
/******************************************************************************************************/
/*IMPORT INDIAN TAKEOUT DATA*/
/******************************************************************************************************/
/******************************************************************************************************/
/*obtain indian takeout data*/
proc import out = temp.indian1
    file = "&inputIndian1"
    dbms = csv REPLACE;
    getnames = yes;
	guessingrows = max;
run;

/*obtain indian takeout data*/
proc import out = temp.indian2
    file = "&inputIndian2"
    dbms = csv REPLACE;
    getnames = yes;
	guessingrows = max;
run;

/*combine data sets*/
proc sql;
	CREATE TABLE temp.indian AS
	SELECT *
	FROM temp.indian1 as indian1

	UNION
	SELECT *, indian2.Order_Number + (SELECT max(Order_Number) FROM temp.indian1) as Order_Number
	FROM temp.indian2 as indian2;
quit;

/*categorize items*/
proc sql;
	CREATE TABLE temp.indian AS
	SELECT distinct *, CASE WHEN upper(Item_Name) like '%SALAD%' OR upper(Item_Name) like '%PICKLE%' 
								OR upper(Item_Name) like '%RICE%' OR upper(Item_Name) like '%NAAN%'
								OR upper(Item_Name) like '%PAPADUM%' OR upper(Item_Name) like '%PARATHA%'
								OR upper(Item_Name) like '%CHAPATI%' OR upper(Item_Name) like '%PUREE%'
								OR upper(Item_Name) like '%FRIES%' OR upper(Item_Name) like '%CHUTNEY%' 
								OR upper(Item_Name) like '%RAITA%' OR upper(Item_Name) like '%RAITHA%'
								OR upper(Item_Name) like '%DAHI%' OR upper(Item_Name) like '%SUACE%'
								THEN 'side'
				   			WHEN upper(Item_Name) like '%CHICKEN%' OR upper(Item_Name) like '%MURGH%'
								OR upper(Item_Name) like '%GARLIC TIKKA CHILLI MASALA%'
								THEN 'chicken'
				   			WHEN upper(Item_Name) like '%LAMB%' OR upper(Item_Name) like '%KEBAB%'
								OR upper(Item_Name) like '%KEHAB%'
								THEN 'lamb'
				   			WHEN upper(Item_Name) like '%FISH%' OR upper(Item_Name) like '%PRAWN%'
								OR upper(Item_Name) like '%JINGA%'
								THEN 'seafood'
				   			WHEN (upper(Item_Name) like '%VEGETABLE%' OR upper(Item_Name) like '%PANEER%'
								OR upper(Item_Name) like '%PANER%' OR upper(Item_Name) like '%ALOO%'
								OR upper(Item_Name) like '%DALL%' OR upper(Item_Name) like '%CAULIFLOWER%' 
								OR upper(Item_Name) like '%MUSHROOM BHAJEE%' OR upper(Item_Name) like '%ONION%'
								OR upper(Item_Name) like '%BHINDI%' OR upper(Item_Name) like '%BAINGAN%'
								OR upper(Item_Name) like '%BANGON%' OR upper(Item_Name) like '%BRINJAL%'
								OR upper(Item_Name) like '%CHANA%' OR upper(Item_Name) like '%SAAG BHAJEE%')
								AND upper(Item_Name) not like '%VINDALOO%' AND upper(Item_Name) not like '%KEEMA ALOO%'
								THEN 'vegetarian'
							WHEN upper(Item_Name) like '%COKE%' OR upper(Item_Name) like '%WATER%'
								OR upper(Item_Name) like '%LEMONADE%' OR upper(Item_Name) like '%WINE%'
				    			OR upper(Item_Name) like '%COBRA%'
								THEN 'drinks'
				   			ELSE 'other'
				   			END AS Food_Category
	FROM temp.indian;
quit;

/******************************************************************************************************/
/******************************************************************************************************/
/*IMPORT WEATHER DATA*/
/******************************************************************************************************/
/******************************************************************************************************/
/*obtain weather data*/
proc import out = temp.weather
    file = "&inputWeather"
    dbms = csv REPLACE;
    getnames = yes;
	guessingrows = max;
run;

/*merge with takeout data on year-month*/
proc sql;
	CREATE TABLE temp.finalData AS
	SELECT indian.Order_Number, year(datepart(indian.Order_Date))*100 + month(datepart(indian.Order_Date)) as Date,
			indian.Item_Name, indian.Quantity, indian.Product_Price, indian.Total_Products, indian.Food_Category,
			weather.min as minTemp, weather.max as maxTemp, (weather.max + weather.min)/2 as meanTemp, weather.AF_days, weather.Rain, weather.Sun
	FROM temp.indian as indian
	JOIN temp.weather as weather
	ON year(datepart(indian.Order_Date)) = weather.year AND month(datepart(indian.Order_Date)) = weather.month
	ORDER BY Order_Date, Order_Number;
quit;

/******************************************************************************************************/
/******************************************************************************************************/
/*EXPORT DATA TO STATA AND CSV FORMAT*/
/******************************************************************************************************/
/******************************************************************************************************/
proc export data = temp.finalData
    outfile = "C:\Users\gelly\Desktop\Github\IndianTakeOut\Indian Merged Data.csv"
    dbms = csv
    replace;
run;
