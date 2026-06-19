USE Produktionsmanagement;
GO

-- 1. Material orders for a specific material
DECLARE @MaterialID INT = 1;

SELECT
    mo.OrderID,
    s.Name AS SupplierName,
    m.Name AS MaterialName,
    mo.Quantity,
    mo.Price,
    mo.OrderDate,
    mo.Status
FROM MaterialOrders mo
JOIN Materials m
    ON mo.MaterialID = m.MaterialID
JOIN Suppliers s
    ON mo.SupplierID = s.SupplierID
WHERE m.MaterialID = @MaterialID;
GO


-- 2. Available stock for a specific material
DECLARE @MaterialID INT = 1;

SELECT
    m.MaterialID,
    m.Name,
    m.Stock,
    m.MinStock,
    CASE
        WHEN m.Stock >= m.MinStock THEN 'Sufficient stock'
        ELSE 'Below minimum stock'
    END AS StockStatus
FROM Materials m
WHERE m.MaterialID = @MaterialID;
GO


-- 3. Open production orders
SELECT
    po.OrderID,
    po.OrderNumber,
    po.OrderDate,
    poi.ItemID,
    poi.ProductID,
    poi.Quantity,
    poi.Status
FROM ProductionOrders po
JOIN ProductionOrderItems poi
    ON po.OrderID = poi.OrderID
WHERE poi.Status = 'Pending';
GO


-- 4. Materials required for a specific product
DECLARE @ProductID INT = 1;

SELECT
    pm.ProductID,
    p.Name AS ProductName,
    m.Name AS MaterialName,
    pm.RequiredQuantity
FROM ProductMaterials pm
JOIN Products p
    ON pm.ProductID = p.ProductID
JOIN Materials m
    ON pm.MaterialID = m.MaterialID
WHERE pm.ProductID = @ProductID;
GO


-- 5. Material availability for processes
SELECT
    p.ProcessID,
    p.ProcessName,
    p.ProductID,
    m.Name AS MaterialName,
    pm.RequiredQuantity,
    m.Stock,
    CASE
        WHEN m.Stock >= pm.RequiredQuantity THEN 'Available'
        ELSE 'Not enough stock'
    END AS AvailabilityStatus
FROM Processes p
JOIN ProductMaterials pm
    ON p.ProductID = pm.ProductID
JOIN Materials m
    ON pm.MaterialID = m.MaterialID;
GO


-- 6. Employees and assigned processes
SELECT
    u.UserID,
    u.Name AS EmployeeName,
    p.ProcessID,
    p.ProcessName,
    p.Status,
    p.StartDate,
    p.EndDate
FROM Users u
JOIN Processes p
    ON u.UserID = p.EmployeeID
WHERE p.Status = 'Pending';
GO


-- 7. Products and inventory levels
SELECT
    ProductID,
    Name,
    Category,
    Leistung_Pferdestärken,
    Stock,
    MinStock,
    Price
FROM Products
ORDER BY Name;
GO


-- 8. Process generation using recursive CTE
WITH NumberSequence AS (
    SELECT
        1 AS ItemNumberFromRequired,
        poi.ItemID,
        poi.ProductID,
        pt.ProcessName,
        poi.Quantity AS QuantityRequired,
        pt.EmployeeID
    FROM ProductionOrderItems poi
    CROSS JOIN ProcessesTemplate pt
    WHERE poi.Quantity > 0

    UNION ALL

    SELECT
        ItemNumberFromRequired + 1,
        ItemID,
        ProductID,
        ProcessName,
        QuantityRequired,
        EmployeeID
    FROM NumberSequence
    WHERE ItemNumberFromRequired < QuantityRequired
)
SELECT
    ItemID,
    ProductID,
    ProcessName,
    EmployeeID,
    QuantityRequired,
    ItemNumberFromRequired
FROM NumberSequence
OPTION (MAXRECURSION 0);
GO
