# Production Management SQL Database

A SQL Server project simulating a manufacturing execution system (MES) for production planning, inventory management and workflow automation.

![SQL Server](https://img.shields.io/badge/SQL_Server-2022-CC2927?logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-Advanced-blue)
![Database Design](https://img.shields.io/badge/Database_Design-3NF-success)
![Data Modeling](https://img.shields.io/badge/Data_Modeling-ERD-green)
![Stored Procedures](https://img.shields.io/badge/Stored_Procedures-Yes-orange)
![Database Triggers](https://img.shields.io/badge/Database_Triggers-Automation-yellow)
![Recursive CTE](https://img.shields.io/badge/Recursive_CTE-Implemented-informational)
![Business Automation](https://img.shields.io/badge/Business_Automation-T--SQL-blueviolet)
![Docker](https://img.shields.io/badge/Docker-SQL_Server-2496ED?logo=docker&logoColor=white)

A relational database project developed in Microsoft SQL Server to support manufacturing planning, inventory management, supplier coordination and production process monitoring.

The system models the complete production lifecycle—from raw material procurement to production execution and finished goods—using a normalized relational database, automated business rules, stored procedures and database triggers.

---

## Business Problem

Manufacturing companies need to coordinate suppliers, raw materials, production orders and shop-floor operations while maintaining accurate inventory levels and production status.

Without a centralized data model, production planning becomes inefficient, inventory shortages are difficult to detect and production progress is hard to monitor.

This project demonstrates how a relational SQL Server database can automate manufacturing workflows, maintain data consistency and support operational decision-making.

---

## Project Objectives

The project was designed to:

* Build a normalized relational database for a manufacturing environment.
* Model relationships between products, materials, suppliers and production orders.
* Automate production workflows using stored procedures and triggers.
* Ensure data consistency through primary keys, foreign keys and constraints.
* Support inventory monitoring and automatic material replenishment.
* Track production processes and order execution in real time.

---

## Entity Relationship Diagram

*(ER Diagram will be added here)*

![ER Diagram](docs/ERD.png)

---

## Database Structure

The database contains 10 business entities:

| Table                | Description                                                            |
| -------------------- | ---------------------------------------------------------------------- |
| Users                | Employees responsible for production processes                         |
| Suppliers            | Material suppliers                                                     |
| Materials            | Raw materials with inventory and minimum stock levels                  |
| MaterialOrders       | Purchase orders for raw materials                                      |
| Products             | Manufactured products                                                  |
| ProductMaterials     | Bill of Materials (BOM) defining required materials for each product   |
| ProductionOrders     | Customer production orders                                             |
| ProductionOrderItems | Individual production items within each order                          |
| ProcessesTemplate    | Template defining the production workflow for each product             |
| Processes            | Individual production process instances generated during manufacturing |

---

## Key Features

### Production Planning

* Production orders containing multiple products
* Product-specific manufacturing workflows
* Multi-step production process management

### Inventory Management

* Raw material inventory tracking
* Minimum stock monitoring
* Automatic material order generation
* Supplier management

### Workflow Automation

* Automatic generation of production processes
* Process status tracking
* Automatic production order status updates
* Inventory updates after production completion

---

## Stored Procedure

### sp_StartProcess

The stored procedure validates raw material availability before allowing a production process to start.

Main functionality:

* Retrieves the product associated with the selected process
* Verifies that all required materials are available
* Prevents process execution if inventory is insufficient
* Updates process status and start time when validation succeeds

---

## Database Triggers

The project includes several business automation triggers:

| Trigger                                 | Purpose                                                                                  |
| --------------------------------------- | ---------------------------------------------------------------------------------------- |
| trg_AutoInsertProcesses                 | Automatically creates production processes for new production order items                |
| trg_InventoryMonitoring                 | Automatically creates purchase orders when inventory falls below the minimum stock level |
| trg_UpdateProductStockOnFinish          | Updates finished product inventory after production completion                           |
| trg_UpdateProductionOrderStatus         | Synchronizes production order status with item status                                    |
| trg_UpdateTimesAndStatusOnStatusChange  | Updates production item dates and status based on process execution                      |
| trg_UpdateDateInProcessesOnStatusChange | Automatically records process start and completion timestamps                            |
| trg_UpdateIsLastProcess                 | Identifies the final production step for each product                                    |

---

## SQL Techniques Demonstrated

* Relational database design (3NF)
* Primary and foreign key relationships
* Composite keys
* Check constraints
* Default constraints
* Stored procedures
* Database triggers
* Recursive Common Table Expressions (CTE)
* Data integrity enforcement
* Business rule automation
* Inventory monitoring
* Production workflow management

---

## Technologies

* Microsoft SQL Server
* T-SQL
* SQL Server Management Studio
* Docker (SQL Server on macOS)
* Visual Studio Code
* DBeaver

---

## Repository Structure

```text
production-management-sql-database
│
├── database/
├── queries/
├── docs/
├── screenshots/
├── data/
└── README.md
```

---

## Future Improvements

Possible extensions include:

* Production KPI dashboard (Power BI)
* Inventory forecasting
* Supplier performance analytics
* Manufacturing lead time analysis
* Role-based user management
* REST API integration
* Python-based reporting and analytics

---

## Author

**Iuliia Chepusova**

SQL Server • Database Design • Data Modeling • Business Process Automation • T-SQL
