Declare @firstName nvarchar(50), @lastName nvarchar (50), @customerID varchar (50) = 29970, @city nvarchar (50), @phone nvarchar (50), @numOfOrders nvarchar (50)


	SELECT @firstName = ISNULL(p.FirstName, 'Unknown'), @lastName = ISNULL(p.LastName, 'Unknown'), 
	@city = ISNULL(a.City, 'Unknown'), @phone = ISNULL(pp.PhoneNumber, 'Unknown'), @numOfOrders = count(*)
	FROM Person.Person p inner join 
	Sales.Customer c on p.BusinessEntityID = c.PersonID left outer join
	Person.BusinessEntityAddress bea on p.BusinessEntityID = bea.BusinessEntityID left outer join
	person.Address a on bea.AddressID = a.AddressID left outer join
	Person.PersonPhone pp on p.BusinessEntityID = pp.BusinessEntityID inner join 
	sales.SalesOrderHeader sod on c.CustomerID = sod.CustomerID
	WHERE c.CustomerID = @customerID
	Group by p.FirstName, p.LastName, a.City, pp.PhoneNumber
	
		Print '------------------------------------------------'
		Print 'Customer Name : ' + @firstName + ' ' + @lastName
		Print 'Customer ID : ' + @customerID
		Print 'City : ' + @city
		Print 'City : ' + @phone
		Print 'Number of Orders : ' + @numOfOrders
		Print '------------------------------------------------'


Declare @order nvarchar(50), @lines nvarchar(50), @orderSum nvarchar (50), @runningTotal nvarchar (50)
DECLARE Cursor_Two CURSOR
local static scroll
FOR
		SELECT h.SalesOrderID, count(*), sum(det.LineTotal)
		FROM sales.SalesOrderHeader h inner join 
		sales.SalesOrderDetail det on h.SalesOrderID = det.SalesOrderID
		WHERE h.CustomerID = @customerID
		Group by h.SalesOrderID

		OPEN Cursor_Two

		fetch next from Cursor_Two
		into @order, @lines, @orderSum
	while @@FETCH_STATUS = 0
	begin
		Print ' '
		Print 'Order # : ' + @order + space (40) + '# of Line items : ' + @lines
		Print '**************************************************************************'
		
		DECLARE @Part_Name nvarchar (50), @qty nvarchar(50), @unitPrice nvarchar (50), @discount nvarchar(50), @counter int, @LineTotal nvarchar(50)
		SET @counter = 1
		DECLARE Cursor_Three CURSOR
		local static scroll
		FOR
			Select p.Name, sod.OrderQty, sum(sod.UnitPrice), sod.UnitPriceDiscount, sod.LineTotal
			FROM Sales.SalesOrderDetail sod inner join 
			Production.Product p on sod.ProductID = p.ProductID
			WHERE sod.SalesOrderID = @order
			GROUP BY p.Name, p.ProductID, sod.OrderQty, sod.UnitPriceDiscount, sod.LineTotal
			ORDER BY sod.UnitPriceDiscount DESC
			
			

			OPEN Cursor_Three

			fetch next from Cursor_Three
			into @Part_Name, @qty, @unitPrice, @discount, @LineTotal
			Print '#' + space(3) + 'Part Name' + space(23) + 'QTY' + space(2) + 'Unit Price' + space(3) + 'Discount' + space(2) + 'Line Total'
			Print '--------------------------------------------------------------------------'
			while @@FETCH_STATUS = 0
			begin
			
			Print LEFT(cast(@counter as nvarchar) + space(3), 3) + LEFT(@Part_Name + space(30),30) + space(3) + LEFT(@qty + space(5),5) + '$' + LEFT(@unitPrice + space(12), 12) + LEFT(case when @discount = '0.00' then '' when cast(@discount as float) > 0 then @discount +'%' end + space(5),5) + 
			+ space(5) + '$' + cast(cast(@LineTotal as money) as nvarchar)
			--cast(					cast(@unitPrice as money) * cast(@qty as money)	- ((cast(@unitPrice as money) * cast(@qty as money)) * (cast(@discount as money)))										as nvarchar)
			

			Set @counter = @counter + 1
			fetch next from Cursor_Three
			into @Part_Name, @qty, @unitPrice, @discount, @LineTotal

			end
			Print '--------------------------------------------------------------------------'
			Print 'Order Total:' + space(52) + '$' + convert(nvarchar,convert(money,@orderSum, 20), 20)
			Print ''
		close Cursor_Three
		deallocate Cursor_Three

		SELECT @runningTotal = sum(h.SubTotal)
		FROM sales.SalesOrderHeader h 
		WHERE h.CustomerID = @customerID



		fetch next from Cursor_Two
		into @order, @lines, @orderSum
	end
		Print '--------------------------------------------------------------------------'
		Print 'Company Total:' + space (50) + '$' + @runningTotal
		Print '--------------------------------------------------------------------------'


close Cursor_Two
deallocate Cursor_Two




