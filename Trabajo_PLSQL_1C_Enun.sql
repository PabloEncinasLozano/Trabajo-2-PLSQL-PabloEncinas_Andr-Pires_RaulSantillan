DROP TABLE detalle_pedido CASCADE CONSTRAINTS;
DROP TABLE pedidos CASCADE CONSTRAINTS;
DROP TABLE platos CASCADE CONSTRAINTS;
DROP TABLE personal_servicio CASCADE CONSTRAINTS;
DROP TABLE clientes CASCADE CONSTRAINTS;

DROP SEQUENCE seq_pedidos;


-- Creación de tablas y secuencias




create sequence seq_pedidos;

CREATE TABLE clientes (
    id_cliente INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    apellido VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(20)
);

CREATE TABLE personal_servicio (
    id_personal INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    apellido VARCHAR2(100) NOT NULL,
    pedidos_activos INTEGER DEFAULT 0 CHECK (pedidos_activos <= 5)
);

CREATE TABLE platos (
    id_plato INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    disponible INTEGER DEFAULT 1 CHECK (DISPONIBLE in (0,1))
);

CREATE TABLE pedidos (
    id_pedido INTEGER PRIMARY KEY,
    id_cliente INTEGER REFERENCES clientes(id_cliente),
    id_personal INTEGER REFERENCES personal_servicio(id_personal),
    fecha_pedido DATE DEFAULT SYSDATE,
    total DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE detalle_pedido (
    id_pedido INTEGER REFERENCES pedidos(id_pedido),
    id_plato INTEGER REFERENCES platos(id_plato),
    cantidad INTEGER NOT NULL,
    PRIMARY KEY (id_pedido, id_plato)
);



-------Insert para las pruebas

 INSERT INTO clientes (id_cliente, nombre, apellido, telefono) 
 VALUES (10, 'Juan', 'Martínez', '555123456');

 INSERT INTO personal_servicio (id_personal, nombre, apellido, pedidos_activos) 
 VALUES (21, 'Pedro', 'Gómez', 0);

 INSERT INTO platos (id_plato, nombre, precio, disponible) 
 VALUES (1, 'Sopa', 12, 1);
 
INSERT INTO platos (id_plato, nombre, precio, disponible) 
 VALUES (7, 'Hamborguesa', 23, 1);

COMMIT;


--------------------------------------------


	
-- Procedimiento a implementar para realizar la reserva
create or replace procedure registrar_pedido(
    arg_id_cliente      INTEGER, 
    arg_id_personal     INTEGER, 
    arg_id_primer_plato INTEGER DEFAULT NULL,
    arg_id_segundo_plato INTEGER DEFAULT NULL
) is 
    
--  Precio plato 1
 plato1 INTEGER :=0 ;
 -- Precio plato 2
 plato2 INTEGER :=0 ;
 -- Precio total del pedido
 total INTEGER :=0 ;
 -- Verificar disponibilidad del plato
 dispo INTEGER :=0 ;
 
 -- Cuenta los pedidos activos del empleado
 ped_activos_empleado INTEGER :=1;
        
 begin
    
    
    IF arg_id_primer_plato is not NULL then
    
        select disponible into dispo
        from platos
        where id_plato = arg_id_primer_plato;
        
        if dispo is NULL then
            rollback;
            raise_application_error(-20004, 'El primer plato seleccionado no existe');
            DBMS_OUTPUT.PUT_LINE('*********** El plato no existe');
        end IF;
        
        if dispo !=0  then
            begin
                select precio into plato1
                from platos 
                where id_plato = arg_id_primer_plato;
            end;
            
        else
            rollback;
            raise_application_error(-20001, 'Uno de los platos seleccionados no esta disponible.');
            DBMS_OUTPUT.PUT_LINE('<><><><><<>< El plato no esta disponible');    
            
        end IF;
    end IF;
    
    
    IF arg_id_segundo_plato is not NULL then
    
        select disponible into dispo
        from platos
        where id_plato = arg_id_segundo_plato;
        
        if dispo is NULL then
            rollback;
            raise_application_error(-20004, 'El segundo plato seleccionado no existe.');
            DBMS_OUTPUT.PUT_LINE('************ El plato no existe');
        end IF;
        
        if dispo !=0 then
            begin
                select precio into plato2
                from platos 
                where id_plato = arg_id_segundo_plato;
            end;  
        else
            rollback;
            raise_application_error(-20001, 'Uno de los platos seleccionados no esta disponible.');
              DBMS_OUTPUT.PUT_LINE('<><><><><<>< El plato no esta disponible');    
        
        end IF;
    end IF;
    
    
    
    total:= plato1+plato2;
    
    IF total !=0 then
    
        select count (*)
        into ped_activos_empleado
        from pedidos
        where id_personal = arg_id_personal;
        
        --Se puede sustituir por:
        --select pedidos_activos into ped_activos_empleado
        --from personal_servicio
        --where id_personal = arg_id_personal;
        
        if ped_activos_empleado < 5 then
        
            --Añadir pedido a tabla pedidos
    
            INSERT INTO pedidos (id_pedido, id_cliente, id_personal, fecha_pedido, total) 
            VALUES (seq_pedidos.nextval, arg_id_cliente, arg_id_personal, CURRENT_DATE, total);
            
            --Añadir los dos platos a detalles_pedido
            
            if arg_id_primer_plato is NOT NULL then
                INSERT INTO detalle_pedido (id_pedido, id_plato, cantidad)
                VALUES (seq_pedidos.nextval, arg_id_primer_plato, 1);
            end IF;
            
            if arg_id_segundo_plato is NOT NULL then
                INSERT INTO detalle_pedido (id_pedido, id_plato, cantidad)
                VALUES (seq_pedidos.nextval, arg_id_segundo_plato, 1);
            end IF;
            
            --Actualizar pedidos activos del empleado en la tabla personal_servicio
            
            UPDATE personal_servicio
            SET pedidos_activos = pedidos_activos+1
            WHERE id_personal = arg_id_personal;
            
            commit;
        
        else 
            rollback;
            raise_application_error(-20003, 'El personal de servicio tiene demasiados pedidos.');
            DBMS_OUTPUT.PUT_LINE('========Limite de pedidos por empleado alcanzado (cambiarlo a exception)');
            
        end IF;
        
    else
        rollback;
        raise_application_error(-20002, 'El pedido debe contener al menos un plato.');
        DBMS_OUTPUT.PUT_LINE('---------No se ha seleccionado ningun plato (cambiarlo a exception)');
             
    end IF;

  --null; -- sustituye esta línea por tu código
   
end;
/


-------<Zona de pruebas>--------

begin

 registrar_pedido(10,21,1,7);
 registrar_pedido(10,21,1);
 registrar_pedido(10,21,NULL,7);
 
 --Revisando seleccion de 0 platos 
 registrar_pedido(10,21,NULL,NULL);
 
 --Revisando limite por empleado
 registrar_pedido(10,21,1,7);
 --registrar_pedido(10,21,1);
 --registrar_pedido(10,21,1);
 
 
 --Revisando no queda ese plato disponible
 
 update platos
 set disponible = 0
 where id_plato=1;
 
 registrar_pedido(10,21,1);
 registrar_pedido(10,21,1,7);


end;
/


select * from pedidos;




---------------------------------

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites apra cada una)
-- * P4.1
--
-- * P4.2
--
-- * P4.3
--
-- * P4.4
--
-- * P4.5
-- 


create or replace
procedure reset_seq( p_seq_name varchar )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/


create or replace procedure inicializa_test is
begin
    
    reset_seq('seq_pedidos');
        
  
    delete from Detalle_pedido;
    delete from Pedidos;
    delete from Platos;
    delete from Personal_servicio;
    delete from Clientes;
    
    -- Insertar datos de prueba
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (1, 'Pepe', 'Perez', '123456789');
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (2, 'Ana', 'Garcia', '987654321');
    
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (1, 'Carlos', 'Lopez', 0);
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (2, 'Maria', 'Fernandez', 5);
    
    insert into Platos (id_plato, nombre, precio, disponible) values (1, 'Sopa', 10.0, 1);
    insert into Platos (id_plato, nombre, precio, disponible) values (2, 'Pasta', 12.0, 1);
    insert into Platos (id_plato, nombre, precio, disponible) values (3, 'Carne', 15.0, 0);

    commit;
end;
/

exec inicializa_test;

-- Completa lost test, incluyendo al menos los del enunciado y añadiendo los que consideres necesarios

create or replace procedure test_registrar_pedido is
begin
	 
  --caso 1 Pedido correct, se realiza
  begin
    inicializa_test;
  end;
  
  -- Idem para el resto de casos

  /* - Si se realiza un pedido vac´ıo (sin platos) devuelve el error -200002.
     - Si se realiza un pedido con un plato que no existe devuelve en error -20004.
     - Si se realiza un pedido que incluye un plato que no est´a ya disponible devuelve el error -20001.
     - Personal de servicio ya tiene 5 pedidos activos y se le asigna otro pedido devuelve el error -20003
     - ... los que os puedan ocurrir que puedan ser necesarios para comprobar el correcto funcionamiento del procedimiento
*/
  
end;
/


set serveroutput on;
exec test_registrar_pedido;
