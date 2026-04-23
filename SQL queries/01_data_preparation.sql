-- DOWNLOAD THE DATASET FROM THE OFFICIAL MICROSOFT LINK AND MOVE IT TO THE 
-- BACKUP FOLDER OF THE SQL SERVER: 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup'
-- THEN RUN THE FOLLOWING CODE:

restore filelistonly
from disk = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorksDW2025.bak';
go


-- USE THE FOLLOWING CODE TO RESTORE THE BACKUP FILE
-- AFTER RESTORING, REFRESH THE SQL SERVER DATABASE IN [OBJECT EXPLORER]
RESTORE DATABASE AdventureWorksDW2025
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorksDW2025.bak'
WITH 
    MOVE 'AdventureWorksDW' 
        TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2025.mdf',
        
    MOVE 'AdventureWorksDW_log'  
        TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2025_log.ldf',
        
    REPLACE,
    RECOVERY,
    STATS = 5;
GO 

-- SET THE ADVENTUREWORKSDW2025 AS DEFAULT SCHEMA FOR THE SCRIPT
use AdventureWorksDW2022;
go 



-- DROP ALL TABLES THAT WE WILL NOT USE IN THE PROJECT
drop table if exists AdventureWorksDWBuildVersion,DatabaseLog,DimAccount,DimOrganization,
DimScenario,FactAdditionalInternationalProductDescription,FactCallCenter,FactCurrencyRate,
FactFinance,FactSalesQuota,FactSurveyResponse,NewFactCurrencyRate,ProspectiveBuyer;
go


-- NOTE: WE CAN NOT SIMPLY DROP THE TABLES BECAUSE OF THE FOREIGN KEY CONSTRAINT.
-- THEREFORE, WE NEED TO DROP FOREIGN KEY CONSTRAINTS AND THEN DROP UNNECESSARY TABLES. 
-- AFTER DROPPING UNNECESSARY TABLES, WE WILL RE-CREATE THE FOREIGN KEY CONSTRAINTS

DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += 
'ALTER TABLE [' + OBJECT_SCHEMA_NAME(parent_object_id) + '].[' 
+ OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' 
+ name + '];' + CHAR(13)

FROM sys.foreign_keys;

EXEC sp_executesql @sql;


-- AFTER EXECUTION OF THE CODE ABOVE, RE-RUN THE TABLE DROPPING COMMAND IN LINE 33-37

-- NOW, INVESTIGATE EACH TABLE, ITS COLUMNS AND DROP UNNECESSARY COLUMNS (PHOTO, EMAIL, LONG ADDRESS LINES AND ETC)

-- ******************************* DATA INVESTIGATION **************************************

-- 1. DIMCURRENCY
select top 5 * from DimCurrency;
GO 


-- 2. DIMCUSTOMER
select top 5 * from DimCustomer;
go

-- THERE ARE SOME UNNECESSARY COLUMNS IN THIS TABLE. LET'S DROP THEM
alter table dimcustomer
drop column title, middlename,namestyle, suffix, emailaddress, 
spanisheducation, frencheducation, spanishoccupation, frenchoccupation,
addressline1, addressline2, phone;


-- 3. DIMDATE
select top 5 * from DimDate;
go

alter table dimdate
drop column
spanishdaynameofweek, frenchdaynameofweek, spanishmonthname, frenchmonthname;
go



-- 4. DIMDEPARTMENTGROUP

select top 5 * from DimDepartmentGroup;
go


-- 5. DIMEMPLOYEE

select top 5 * from DimEmployee;
go

alter table DimEmployee
drop column
parentemployeenationalidalternatekey,
middlename, namestyle, loginid, emailaddress, phone, 
emergencycontactname, emergencycontactphone, employeephoto;
go



-- 6. DIMGEOGRAPHY
select top 5 * from DimGeography;

alter table dimgeography
drop column
spanishcountryregionname, frenchcountryregionname;


-- 7. DIMPRODUCT
select top 5 * from DimProduct; 

alter table dimproduct
drop column 
englishdescription, spanishproductname, frenchproductname, color, safetystocklevel,
reorderpoint, largephoto, frenchdescription, chinesedescription, arabicdescription,
hebrewdescription, thaidescription, germandescription, japanesedescription, turkishdescription;
go



-- 8. DIMPRODUCTCATEGORY
select top 5 * from DimProductCategory; 

alter table dimproductcategory 
drop column
spanishproductcategoryname, frenchproductcategoryname;


-- 9. DIMPRODUCTSUBCATEGORY
select top 5 * from DimProductSubcategory; 

alter table DimProductSubcategory 
drop column
spanishproductsubcategoryname, frenchproductsubcategoryname;


-- 10. DIMPROMOTION
select top 5 * from DimPromotion; 

alter table DimPromotion 
drop column
spanishpromotionname, frenchpromotionname, spanishpromotiontype,
frenchpromotiontype, spanishpromotioncategory, frenchpromotioncategory;
go


-- 11. DIMRESELLER
select top 5 * from DimReseller; 

alter table DimReseller 
drop column
phone, addressline1,addressline2;
go


-- 12. DIMSALESREASON
select top 5 * from DimSalesReason; 




-- 13. DIMSALESTERRITORY
select top 5 * from DimSalesTerritory; 

alter table DimSalesTerritory 
drop column
salesterritoryimage;



-- 14. FACTINTERNETSALES

select top 5 * from FactInternetSales; 

alter table FactInternetSales 
drop column
promotionkey, carriertrackingnumber, customerponumber;


-- 15. FACTINTERNETSALESREASON

select top 5 * from FactInternetSalesReason; 



-- 16. FACTPRODUCTINVENTORY

select top 5 * from FactProductInventory; 


-- 17. FACTRESELLERSALES

select top 5 * from FactResellerSales; 

alter table FactResellerSales 
drop column
carriertrackingnumber, customerponumber;




-- ******************************* SCHEMA MODELLING **************************************

-- IN THIS PART, WE WILL ADD FOREIGN KEY CONSTRAINTS TO BUILD RELATIONS BETWEEN TABLES

-- FACTINTERNETSALES: CREATE ALL NECESSARY FOREIGN KEY CONSTRAINTS IN THIS TABLE

-- internetsales vs products
alter table factinternetsales
add constraint FK_InternetSales_Products
foreign key (ProductKey)
references dimproduct(ProductKey);
go

-- internetsales and calendar (orderdate, duedate, shipdate)
alter table factinternetsales
add constraint FK_InternetSales_Date_Orderdate
foreign key (orderdatekey)
references dimdate(datekey);
go

alter table factinternetsales
add constraint FK_InternetSales_Date_Duedate
foreign key (duedatekey)
references dimdate(datekey);
go

alter table factinternetsales
add constraint FK_InternetSales_Date_Shipdate
foreign key (shipdatekey)
references dimdate(datekey);
go

-- internetsales and customers
alter table factinternetsales
add constraint FK_InternetSales_Customers
foreign key (customerkey)
references dimcustomer(customerkey);
go

-- internetsales and currency
alter table factinternetsales
add constraint FK_InternetSales_Currency
foreign key (currencykey)
references dimcurrency(currencykey);
go

-- internetsales and salesterritory
alter table factinternetsales
add constraint FK_InternetSales_SalesTerritory
foreign key (salesterritorykey)
references dimsalesterritory(salesterritorykey);
go





-- FACTRESELLERSALES: CREATE ALL NECESSARY FOREIGN KEY CONSTRAINTS IN THIS TABLE

-- resellersales vs products
alter table factresellersales
add constraint FK_ResellerSales_Products
foreign key (ProductKey)
references dimproduct(ProductKey);
go

-- resellersales and calendar (orderdate, duedate, shipdate)
alter table factresellersales
add constraint FK_ResellerSales_Date_Orderdate
foreign key (orderdatekey)
references dimdate(datekey);
go

alter table factresellersales
add constraint FK_ResellerSales_Date_Duedate
foreign key (duedatekey)
references dimdate(datekey);
go

alter table factresellersales
add constraint FK_ResellerSales_Date_Shipdate
foreign key (shipdatekey)
references dimdate(datekey);
go

-- resellersales and resellers
alter table factresellersales
add constraint FK_ResellerSales_Reseller
foreign key (resellerkey)
references dimreseller(resellerkey);
go


-- resellersales and employee
alter table factresellersales
add constraint FK_ResellerSales_Employee
foreign key (employeekey)
references dimemployee(employeekey);
go


-- resellersales and promotion
alter table factresellersales
add constraint FK_ResellerSales_Promotion
foreign key (promotionkey)
references dimpromotion(promotionkey);
go



-- resellersales and currency
alter table factresellersales
add constraint FK_ResellerSales_Currency
foreign key (currencykey)
references dimcurrency(currencykey);
go

-- resellersales and salesterritory
alter table factresellersales
add constraint FK_ResellerSales_SalesTerritory
foreign key (salesterritorykey)
references dimsalesterritory(salesterritorykey);
go



-- DIMCUSTOMER
alter table dimcustomer
add constraint FK_Customer_Geography
foreign key (geographykey)
references dimgeography(geographykey);
go


-- DIMEMPLOYEE
alter table dimemployee
add constraint FK_Employee_SalesTerritory
foreign key (salesterritorykey)
references dimsalesterritory(salesterritorykey);
go

-- DIMGEOGRAPHY
alter table dimgeography
add constraint FK_Geography_SalesTerritory
foreign key (salesterritorykey)
references dimsalesterritory(salesterritorykey);
go


-- DIMPRODUCT
alter table dimproduct
add constraint FK_Product_ProductSubcategory
foreign key (productsubcategorykey)
references dimproductsubcategory(productsubcategorykey);
go

-- DIMPRODUCTSUBCATEGORY
alter table dimproductsubcategory
add constraint FK_ProductSubcategory_ProductCategory
foreign key (productcategorykey)
references dimproductcategory(productcategorykey);
go


-- DIMRESELLER
alter table dimreseller
add constraint FK_Reseller_Geography
foreign key (geographykey)
references dimgeography(geographykey);
go



-- FACTPRODUCTINVENTORY

-- factproductinventory and dimproduct
alter table factproductinventory
add constraint FK_ProductInventory_Products
foreign key (productkey)
references dimproduct(productkey);
go

-- factproductinventory and dimdate
alter table factproductinventory
add constraint FK_ProductInventory_Date
foreign key (datekey)
references DimDate(datekey);
go


-- FACTINTERNETSALESREASON

-- factinternetsalesreason and salesreason
alter table factinternetsalesreason
add constraint FK_InternetSalesReason_SalesReason
foreign key (salesreasonkey)
references salesreason(salesreasonkey);
go


















