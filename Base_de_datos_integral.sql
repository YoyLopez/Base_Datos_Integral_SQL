-- SQL Server - Script --
-- Creando base de datos integral --

USE master
GO

-- Creando una base de datos
CREATE DATABASE INVENTARIODB
GO


--DROP DATABASE INVENTARIODB
--GO


--====================================

-- Activar la base de datos 
USE INVENTARIODB; 
GO

-- Creando tablas 

--Tabla de Productos

--tabla de Proveedores
CREATE TABLE Proveedores (
    ID_Proveedor INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Dirección VARCHAR(255)
);

CREATE TABLE Productos (
    ID_Producto INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Precio DECIMAL(10,2),
    Stock INT,
    ID_Proveedor INT,
    FOREIGN KEY (ID_Proveedor) REFERENCES Proveedores(ID_Proveedor)
);

--tabla de Clientes
CREATE TABLE Clientes (
    ID_Cliente INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Dirección VARCHAR(255)
);


--tabla de Pedidos
CREATE TABLE Pedidos (
    ID_Pedido INT PRIMARY KEY,
    Fecha DATE,
    ID_Cliente INT,
    FOREIGN KEY (ID_Cliente) REFERENCES Clientes(ID_Cliente)
);


--Tabla de DetallesPedidos
CREATE TABLE DetallesPedidos (
    ID_Detalle INT PRIMARY KEY,
    ID_Pedido INT,
    ID_Producto INT,
    Cantidad INT,
    FOREIGN KEY (ID_Pedido) REFERENCES Pedidos(ID_Pedido),
    FOREIGN KEY (ID_Producto) REFERENCES Productos(ID_Producto)
);
--es necesario crear primero las tablas que solo tengan una llave primaria
--para luego poder agrupar
GO



--Insertar datos artificiales

--Proveedores
INSERT INTO Proveedores (ID_Proveedor, Nombre, Dirección)
VALUES 
(001, 'Proveedor 1', 'Santa Rosalia 123'),
(002, 'Proveedor 2', 'Rio Tambo 456'),
(003, 'Proveedor 3', 'Avenida Universitaria 789');

--Productos
INSERT INTO Productos (ID_Producto, Nombre, Precio, Stock, ID_Proveedor)
VALUES 
(01, 'Producto A', 10.50, 100, 001),
(02, 'Producto B', 20.50, 50, 002),
(03, 'Producto C', 15.50, 150, 003);

--Clientes
INSERT INTO Clientes (ID_Cliente, Nombre, Dirección)
VALUES 
(0001, 'Cliente 1', 'La Marina 321'),
(0002, 'Cliente 2', 'La Mar 654'),
(0003, 'Cliente 3', 'Rio tambo 987');


--Pedidos
INSERT INTO Pedidos (ID_Pedido, Fecha, ID_Cliente)
VALUES 
(000001, '2024-04-19', 0001),
(000002, '2024-04-18', 0002),
(000003, '2024-04-17', 0003);


-- Detalles de Pedidos
INSERT INTO DetallesPedidos (ID_Detalle, ID_Pedido, ID_Producto, Cantidad)
VALUES 
(1, 000001, 01, 3),
(2, 000001, 02, 2),
(3, 000002, 02, 1),
(4, 000003, 03, 4);

--Prueba
SELECT * FROM Proveedores
GO

SELECT * FROM Productos
GO

SELECT * FROM Clientes
GO

SELECT * FROM Pedidos
GO

SELECT * FROM DetallesPedidos
GO


--PROCEDIMIENTOS ALMACENADOS
-- Procedimiento para añadir un nuevo producto
CREATE PROCEDURE AñadirProducto 
    @NombreProducto VARCHAR(100),
    @Precio DECIMAL(10,2),
    @Stock INT,
    @ID_Proveedor INT
AS
BEGIN
    INSERT INTO Productos (Nombre, Precio, Stock, ID_Proveedor)
    VALUES (@NombreProducto, @Precio, @Stock, @ID_Proveedor);
END;
GO


CREATE PROCEDURE ActualizarStock 
    @ProductoID INT,
    @NuevoStock INT
AS
BEGIN
    UPDATE Productos
    SET Stock = @NuevoStock
    WHERE ID_Producto = @ProductoID;
END;
GO

CREATE TYPE DetallesPedidoType AS TABLE (
    ID_Producto INT,
    Cantidad INT
);
GO


CREATE PROCEDURE RegistrarPedido 
    @ClienteID INT,
    @DetallesPedido DetallesPedidoType READONLY
AS
BEGIN
    DECLARE @PedidoID INT;

    -- Insertar en la tabla Pedidos
    INSERT INTO Pedidos (Fecha, ID_Cliente)
    VALUES (GETDATE(), @ClienteID);

    -- Obtener el ID del último pedido insertado
    SET @PedidoID = SCOPE_IDENTITY();

    -- Insertar los detalles del pedido
    INSERT INTO DetallesPedidos (ID_Pedido, ID_Producto, Cantidad)
    SELECT @PedidoID, ID_Producto, Cantidad FROM @DetallesPedido;
END;
GO



-- Trigger de Auditoría para Productos

CREATE TRIGGER AuditarProductos
ON Productos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Insertar registros en la tabla de auditoría para operaciones de inserción
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaProductos (ID_Producto, Nombre, Precio, Stock, ID_Proveedor, Operacion)
        SELECT ID_Producto, Nombre, Precio, Stock, ID_Proveedor, 'INSERT'
        FROM inserted;
    END
    
    -- Insertar registros en la tabla de auditoría para operaciones de actualización
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaProductos (ID_Producto, Nombre, Precio, Stock, ID_Proveedor, Operacion)
        SELECT ID_Producto, Nombre, Precio, Stock, ID_Proveedor, 'UPDATE'
        FROM inserted;
    END

    -- Insertar registros en la tabla de auditoría para operaciones de eliminación
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO AuditoriaProductos (ID_Producto, Nombre, Precio, Stock, ID_Proveedor, Operacion)
        SELECT ID_Producto, Nombre, Precio, Stock, ID_Proveedor, 'DELETE'
        FROM deleted;
    END
END;
GO

-- Trigger para validar el stock antes de insertar un pedido

CREATE TRIGGER ValidarStockAntesInsertarDetalle
ON DetallesPedidos
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Productos p ON i.ID_Producto = p.ID_Producto
        WHERE i.Cantidad > p.Stock
    )
    BEGIN
        RAISERROR ('No hay suficiente stock para uno o más productos.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Si hay suficiente stock, proceder con la inserción
    INSERT INTO DetallesPedidos (ID_Pedido, ID_Producto, Cantidad)
    SELECT ID_Pedido, ID_Producto, Cantidad FROM inserted;
END;
GO

--------

CREATE VIEW VistaPedidosDetallesClientes AS
SELECT 
    p.ID_Pedido,
    p.Fecha,
    c.ID_Cliente,
    c.Nombre AS NombreCliente,
    c.Dirección AS DireccionCliente,
    dp.ID_Producto,
    pr.Nombre AS NombreProducto,
    pr.Precio,
    dp.Cantidad,
    (dp.Cantidad * pr.Precio) AS TotalProducto
FROM 
    Pedidos p
JOIN 
    Clientes c ON p.ID_Cliente = c.ID_Cliente
JOIN 
    DetallesPedidos dp ON p.ID_Pedido = dp.ID_Pedido
JOIN 
    Productos pr ON dp.ID_Producto = pr.ID_Producto;
GO
---------


CREATE VIEW Vista_Stock_Bajo AS
SELECT 
    ID_Producto,
    Nombre,
    Precio,
    Stock,
    ID_Proveedor
FROM 
    Productos
WHERE 
    Stock < 60;
GO
------------
-- Consultar información de pedidos con detalles y clientes
SELECT * FROM VistaPedidosDetallesClientes;
GO

-- Consultar productos con stock bajo
SELECT * FROM Vista_Stock_Bajo;
GO

---------
-- Función para calcular el total del pedido incluyendo impuestos
CREATE FUNCTION CalcularTotalPedido(@ID_Pedido INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @Total DECIMAL(10, 2);
    DECLARE @Impuesto DECIMAL(10, 2) = 0.18;

    SELECT @Total = SUM(dp.Cantidad * p.Precio)
    FROM DetallesPedidos dp
    JOIN Productos p ON dp.ID_Producto = p.ID_Producto
    WHERE dp.ID_Pedido = @ID_Pedido;

    RETURN @Total + (@Total * @Impuesto);
END;
GO




-- Función para devolver el estado del stock de un producto
CREATE FUNCTION EstadoStockProducto(@ID_Producto INT)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @Stock INT;
    DECLARE @Estado VARCHAR(10);

    SELECT @Stock = Stock FROM Productos WHERE ID_Producto = @ID_Producto;

    IF @Stock > 50
        SET @Estado = 'Alto';
    ELSE IF @Stock >= 20 AND @Stock <= 50
        SET @Estado = 'Medio';
    ELSE
        SET @Estado = 'Bajo';

    RETURN @Estado;
END;
GO


-------------------
-- Calcular el total del pedido con ID 1, incluyendo impuestos
SELECT dbo.CalcularTotalPedido(1) AS TotalPedidoConImpuestos;
GO

-- Obtener el estado del stock del producto con ID 1
SELECT dbo.EstadoStockProducto(1) AS EstadoStock;
GO

