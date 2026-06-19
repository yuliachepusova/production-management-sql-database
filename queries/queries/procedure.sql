USE Produktionsmanagement;
GO

/* 
Stored Procedure: sp_StartProcess

Purpose:
Checks whether all required materials are available before starting
a production process. If material stock is insufficient, the process
is not started.
*/

CREATE OR ALTER PROCEDURE [dbo].[sp_StartProcess]
    @ProcessID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID INT;

    SELECT @ProductID = p.ProductID
    FROM Processes p
    WHERE p.ProcessID = @ProcessID;

    DECLARE @MaterialID INT;
    DECLARE @RequiredQuantity INT;
    DECLARE @AvailableStock INT;

    DECLARE material_cursor CURSOR FOR
        SELECT 
            pm.MaterialID,
            pm.RequiredQuantity
        FROM ProductMaterials pm
        WHERE pm.ProductID = @ProductID;

    OPEN material_cursor;

    FETCH NEXT FROM material_cursor 
    INTO @MaterialID, @RequiredQuantity;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @AvailableStock = Stock
        FROM Materials
        WHERE MaterialID = @MaterialID;

        IF @AvailableStock < @RequiredQuantity
        BEGIN
            PRINT 'Not enough raw materials available for MaterialID: ' 
                + CAST(@MaterialID AS VARCHAR);

            CLOSE material_cursor;
            DEALLOCATE material_cursor;
            RETURN;
        END

        FETCH NEXT FROM material_cursor 
        INTO @MaterialID, @RequiredQuantity;
    END

    CLOSE material_cursor;
    DEALLOCATE material_cursor;

    UPDATE Processes
    SET 
        Status = 'Active',
        StartDate = GETDATE()
    WHERE ProcessID = @ProcessID;

    PRINT 'Process started: ' + CAST(@ProcessID AS VARCHAR);
END;
GO
