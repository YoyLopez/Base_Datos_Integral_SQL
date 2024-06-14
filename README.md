# :octocat: Proyecto de Base de Datos Integral

Objetivo: Construir una base de datos para un sistema de gestión de inventario de una tienda minorista virtual que incluya productos, proveedores, clientes, pedidos y auditoría de transacciones.
Requerimientos del Proyecto:
1.  Diseño de la Base de Datos:
· Definir los esquemas necesarios para organizar las tablas y otros objetos de la base de datos.
2. Creación de Tablas Iniciales:
· Productos: Para almacenar información sobre los productos.
· Proveedores: Para registrar los proveedores de los productos.
· Clientes: Para mantener un registro de los clientes.
· Pedidos: Para registrar los pedidos realizados por los clientes.
· DetallesPedidos: Para detallar los productos incluidos en cada pedido.
3. Procedimientos Almacenados:
· Crear un procedimiento para añadir un nuevo producto.
· Desarrollar un procedimiento para actualizar el stock de un producto.
· Escribir un procedimiento para registrar un nuevo pedido.
4. Triggers:
· Implementar un trigger para auditar los cambios en la tabla de productos.
· Configurar un trigger para validar el stock antes de insertar un pedido.
5. Vistas:
· Crear una vista que muestre la información del pedido con detalles del producto y la información del cliente.
· Desarrollar una vista para visualizar el stock de productos por debajo de un umbral mínimo.
6. Funciones:
· Escribir una función que calcule el total del pedido incluyendo impuestos.
· Crear una función que devuelva el estado del stock de un producto ('Alto', 'Medio', 'Bajo').
