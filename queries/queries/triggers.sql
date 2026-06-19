USE Produktionsmanagement;
GO

/*
Trigger: trg_UpdateProductStockOnFinish

Purpose:
Updates product stock when a production order item is marked as finished.
*/

CREATE OR ALTER TRIGGER trg_UpdateProductStockOnFinish
ON ProductionOrderItems
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.Stock = p.Stock + i.Quantity
    FROM Products p
    INNER JOIN inserted i
        ON p.ProductID = i.ProductID
    WHERE i.finished = 1;
END;
GO


/*
Trigger: trg_UpdateProductionOrderStatus

Purpose:
Updates the overall production order status based on the status
of related production order items.
*/

CREATE OR ALTER TRIGGER trg_UpdateProductionOrderStatus
ON ProductionOrderItems
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE po
    SET po.Status =
        CASE
            WHEN NOT EXISTS (
                SELECT 1
                FROM ProductionOrderItems poi
                WHERE poi.OrderID = po.OrderID
                  AND poi.finished = 0
            ) THEN 'Finished'

            WHEN EXISTS (
                SELECT 1
                FROM ProductionOrderItems poi
                WHERE poi.OrderID = po.OrderID
                  AND poi.activ = 1
            ) THEN 'In production'

            ELSE po.Status
        END
    FROM ProductionOrders po
    INNER JOIN inserted i
        ON i.OrderID = po.OrderID;
END;
GO


/*
Trigger: trg_UpdateIsLastProcess

Purpose:
Marks the final production process step for each product.
*/

CREATE OR ALTER TRIGGER trg_UpdateIsLastProcess
ON Processes
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.IsLastProcess =
        CASE
            WHEN pt.SequenceOrder = (
                SELECT MAX(pt2.SequenceOrder)
                FROM ProcessesTemplate pt2
                WHERE pt2.ProductID = p.ProductID
            ) THEN 1
            ELSE 0
        END
    FROM Processes p
    INNER JOIN ProcessesTemplate pt
        ON p.ProcessName = pt.ProcessName
       AND p.ProductID = pt.ProductID;
END;
GO


/*
Trigger: trg_UpdateTimesAndStatusOnStatusChange

Purpose:
Updates activity flags, finish flags, start dates and end dates
in ProductionOrderItems based on related process statuses.
*/

CREATE OR ALTER TRIGGER trg_UpdateTimesAndStatusOnStatusChange
ON Processes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE poi
    SET
        activ =
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM Processes p
                    WHERE p.ItemID = poi.ItemID
                      AND p.Status = 'Active'
                ) THEN 1
                ELSE 0
            END,

        finished =
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM Processes p
                    WHERE p.ItemID = poi.ItemID
                      AND p.IsLastProcess = 1
                      AND p.Status <> 'Finished'
                ) THEN 1
                ELSE 0
            END,

        StartDate =
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM Processes p
                    WHERE p.ItemID = poi.ItemID
                      AND p.Status = 'Active'
                )
                AND poi.StartDate IS NULL
                THEN GETDATE()
                ELSE poi.StartDate
            END,

        EndDate =
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM Processes p
                    WHERE p.ItemID = poi.ItemID
                      AND p.Status <> 'Finished'
                )
                THEN GETDATE()
                ELSE poi.EndDate
            END
    FROM ProductionOrderItems poi
    WHERE poi.ItemID IN (
        SELECT DISTINCT ItemID
        FROM inserted
    );
END;
GO


/*
Trigger: trg_UpdateDateInProcessesOnStatusChange

Purpose:
Automatically updates process start and end dates when process status changes.
*/

CREATE OR ALTER TRIGGER trg_UpdateDateInProcessesOnStatusChange
ON Processes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET
        StartDate =
            CASE
                WHEN i.Status = 'Active'
                 AND p.StartDate IS NULL
                THEN GETDATE()
                ELSE p.StartDate
            END,

        EndDate =
            CASE
                WHEN i.Status = 'Finished'
                THEN GETDATE()
                ELSE p.EndDate
            END
    FROM Processes p
    INNER JOIN inserted i
        ON p.ProcessID = i.ProcessID;
END;
GO


/*
Trigger: trg_InventoryMonitoring

Purpose:
Automatically creates material orders when material stock falls below
the minimum stock level.
*/

CREATE OR ALTER TRIGGER trg_InventoryMonitoring
ON Materials
AFTER UPDATE, INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO MaterialOrders (
        SupplierID,
        MaterialID,
        Quantity,
        Price,
        OrderDate,
        Status
    )
    SELECT
        m.SupplierID,
        m.MaterialID,
        (i.MinStock - m.Stock),
        m.Price * (i.MinStock - m.Stock),
        GETDATE(),
        'Registered'
    FROM Materials m
    INNER JOIN inserted i
        ON m.MaterialID = i.MaterialID
    WHERE m.Stock < i.MinStock;

    DECLARE @MaterialID INT;
    DECLARE @Name VARCHAR(100);

    DECLARE warning_cursor CURSOR FOR
        SELECT 
            i.MaterialID,
            i.Name
        FROM inserted i
        INNER JOIN Materials m
            ON i.MaterialID = m.MaterialID
        WHERE m.Stock < i.MinStock;

    OPEN warning_cursor;

    FETCH NEXT FROM warning_cursor 
    INTO @MaterialID, @Name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Warning! Automatic order required for MaterialID: '
            + CAST(@MaterialID AS VARCHAR)
            + ', '
            + @Name;

        FETCH NEXT FROM warning_cursor 
        INTO @MaterialID, @Name;
    END

    CLOSE warning_cursor;
    DEALLOCATE warning_cursor;
END;
GO


/*
Trigger: trg_AutoInsertProcesses

Purpose:
Automatically generates process instances after inserting new production
order items. Uses a recursive CTE to generate one process sequence per
ordered item quantity.
*/

CREATE OR ALTER TRIGGER trg_AutoInsertProcesses
ON ProductionOrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    WITH NumberSequence AS (
        SELECT
            1 AS ItemNumberFromRequired,
            poi.ItemID,
            poi.ProductID,
            pt.ProcessName,
            poi.Quantity AS QuantityRequired,
            pt.EmployeeID
        FROM inserted poi
        CROSS JOIN ProcessesTemplate pt
        WHERE poi.Quantity > 0

        UNION ALL

        SELECT
            ns.ItemNumberFromRequired + 1,
            ns.ItemID,
            ns.ProductID,
            ns.ProcessName,
            ns.QuantityRequired,
            ns.EmployeeID
        FROM NumberSequence ns
        WHERE ns.ItemNumberFromRequired < ns.QuantityRequired
    )

    INSERT INTO Processes (
        ItemID,
        ProductID,
        ProcessName,
        EmployeeID,
        QuantityRequired,
        ItemNumberFromRequired
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
END;
GO
