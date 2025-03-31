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
/*
 INSERT INTO clientes (id_cliente, nombre, apellido, telefono) 
 VALUES (10, 'Juan', 'Martínez', '555123456');

 INSERT INTO personal_servicio (id_personal, nombre, apellido, pedidos_activos) 
 VALUES (21, 'Pedro', 'Gómez', 0);

 INSERT INTO platos (id_plato, nombre, precio, disponible) 
 VALUES (1, 'Sopa', 12, 1);
 
INSERT INTO platos (id_plato, nombre, precio, disponible) 
 VALUES (7, 'Hamborguesa', 23, 1);

COMMIT;
*/

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
 
 
  IdPed INTEGER :=0 ;
 
 -- Cuenta los pedidos activos del empleado
 ped_activos_empleado INTEGER :=1;
        
 begin
    
    -- Revision primer plato
    IF arg_id_primer_plato is not NULL then
    
        -- Comporbamos si existe
        begin
            select disponible into dispo
            from platos
            where id_plato = arg_id_primer_plato;
        exception
            when NO_DATA_FOUND then
            rollback;
            RAISE_APPLICATION_ERROR(-20004, 'El primer plato seleccionado no existe.');
        end;

        -- Comprobamos si esta disponible
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
   
    
    -- Revison del segundo plato
    IF arg_id_segundo_plato is not NULL then
    
         -- Comporbamos si existe
        begin
            select disponible into dispo
            from platos
            where id_plato = arg_id_segundo_plato;
        exception
            when NO_DATA_FOUND then
            rollback;
            RAISE_APPLICATION_ERROR(-20004, 'El primer plato seleccionado no existe.');
        end;
        
        -- Comprobamos si esta disponible
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
    
    -- Revision si se ha pedido plato
    IF total !=0 then
        
        select pedidos_activos into ped_activos_empleado
        from personal_servicio
        where id_personal = arg_id_personal
        FOR UPDATE;
        
        -- Revisar pedidos activos del empleado
        if ped_activos_empleado < 5 then
        
            IdPed:=seq_pedidos.nextval;
        
            --Añadir pedido a tabla pedidos
    
            INSERT INTO pedidos (id_pedido, id_cliente, id_personal, fecha_pedido, total) 
            VALUES (IdPed, arg_id_cliente, arg_id_personal, CURRENT_DATE, total);
            
            --Añadir los dos platos a detalles_pedido
              
            
            if arg_id_primer_plato is NOT NULL then
                INSERT INTO detalle_pedido (id_pedido, id_plato, cantidad)
                VALUES (IdPed, arg_id_primer_plato, 1);
                commit;
            end IF;
            
            if arg_id_segundo_plato is NOT NULL then
                INSERT INTO detalle_pedido (id_pedido, id_plato, cantidad)
                VALUES (IdPed, arg_id_segundo_plato, 1);
                commit;
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


/*
-------<Zona de pruebas>--------

begin

 
 --registrar_pedido(10,21,1);
 --registrar_pedido(10,21,NULL,7);
 
 --Revisando seleccion de 0 platos 
 --registrar_pedido(10,21,NULL,NULL);
 
 --Revisando limite por empleado
 --registrar_pedido(10,21,1,7);
 --registrar_pedido(10,21,1);
 --registrar_pedido(10,21,1);
 
 
 --Revisando no queda ese plato disponible
 
 --update platos
 --set disponible = 0
 --where id_plato=1;
 

 --registrar_pedido(10,21,1,7);



end;
/

*/

select * from personal_servicio;

select * from pedidos;

select * from detalle_pedido;



---------------------------------

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites apra cada una)
-- * P4.1  ¿Como garantizas en tu codigo que un miembro del personal de servicio no supere el lımite de pedidos activos?
-- Se revisa que, de un id de empleado concreto pasado por argumento, este no tenga mas de 5 pedidos. En caso de que
-- si tenga 5 pedidos activos, se lanzara la excepcion 20003 donde se avisara que el limite de pedidos activos de ese emplado
-- se ha alcanzado.
--
-- * P4.2
--
-- * P4.3
--
-- * P4.4
--
-- * P4.5 ¿Que tipo de estrategia de programacion has utilizado? ¿Como puede verse en tu codigo?
-- La estrategia principal que se ha usado ha sido defensiva ya que se ha ido haciendo una revision de los datos guardados
-- antes de modificar cualquier tabla involucrada. Aun asi, hay dos puntos, en la revision de si existen los platos, que
-- se ha usado una estrategia intermedia, ya que tras hacer el select, se hace el tratamiento de la excepcion en caso 
-- de que esta select devuelva un error de tipo NO_DATA_FOUND.


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
  dbms_output.put_line('------------------Test1: Pedido correcto se registra adecuadamente------------------');

  -- Registrar un pedido
  registrar_pedido(1, 1, 1, 2);
  
  -- Verificar que el pedido se ha insertado en la tabla PEDIDOS
  Declare
    pedidos INTEGER;
  begin
    select count(*) into pedidos
    from pedidos 
    where id_cliente = 1 and id_personal = 1;
    
    IF pedidos = 1 THEN
      dbms_output.put_line('BIEN: El pedido se ha registrado en la tabla PEDIDOS');
    else
      dbms_output.put_line('MAL: El pedido no se ha registrado correctamente en la tabla PEDIDOS');
    end IF;
  end;

  -- Verificar que los platos se han insertado en la tabla DETALLE_PEDIDO
  declare
    detalle_pedidos INTEGER;
  begin
    select count(*) into detalle_pedidos
    from detalle_pedido 
    where id_plato in (1, 2);
    
    IF detalle_pedidos = 2 then
      dbms_output.put_line('BIEN: Los platos se han registrado en la tabla DETALLE_PEDIDO');
    else
      dbms_output.put_line('MAL: Los platos no se han registrado correctamente en la tabla DETALLE_PEDIDO.);
    end if;
  end;

  -- Verificar que se ha actualizado el número de pedidos activos del personal
  declare
    pedidos_activos INTEGER;
  begin
    select pedidos_activos into pedidos_activos 
    from personal_servicio 
    where id_personal = 1;
    
    IF pedidos_activos = 1 then
      dbms_output.put_line('BIEN: Se ha actualizado el número de pedidos activos del personal');
    else
      dbms_output.put_line('MAL: No se ha actualizado correctamente el numero de pedidos activos del personal');
    end IF;
  end;
  
  
  begin
    inicializa_test;
  end;
  
  -- Idem para el resto de casos


 -- Si se realiza un pedido vac´ıo (sin platos) devuelve el error -200002.
 
    begin
    dbms_output.put_line('------------------Test2: Realizar un pedido vacio (sin platos)------------------');
    registrar_pedido(1,1);
    rollback;
    dbms_output.put_line('MAL: No da error al hacer pedido sin platos.');
  exception
    when others then
      if SQLCODE = -20002 then
        dbms_output.put_line('BIEN: Detecta pedido sin platos y no hace la reserva.');
        dbms_output.put_line('Error nro '||SQLCODE);
        dbms_output.put_line('Mensaje '||SQLERRM);
      else
        dbms_output.put_line('MAL: Da error pero no detecta que fallo al hacer la reserva.');
        dbms_output.put_line('Error nro '||SQLCODE);
        dbms_output.put_line('Mensaje '||SQLERRM);
      end if;
  end;
  
  
  
     -- Si se realiza un pedido con un plato que no existe devuelve en error -20004.
     
    begin
        dbms_output.put_line('------------------Test3: Realizar un pedido de un plato que no existe------------------');
        registrar_pedido(1,1,4);
        rollback;
        dbms_output.put_line('MAL: No da error al hacer un pedido con un plato que no existe.');
    exception
        when others then
        if SQLCODE = -20004 then
            dbms_output.put_line('BIEN: Detecta que el plato no existe y no hace el pedido.');
            dbms_output.put_line('Error nro '||SQLCODE);
            dbms_output.put_line('Mensaje '||SQLERRM);
        else
            dbms_output.put_line('MAL: Da error pero no detecta que fallo al hacer la reserva.');
            dbms_output.put_line('Error nro '||SQLCODE);
            dbms_output.put_line('Mensaje '||SQLERRM);
        end if;
    end;
    
    
     -- Si se realiza un pedido que incluye un plato que no est´a ya disponible devuelve el error -20001.
     
     begin
      dbms_output.put_line('------------------Test4: Realiza un pedido con plato no disponible------------------');
      registrar_pedido(1,1,3);
      dbms_output.put_line('MAL: No da error al hacer pedido con platos no disponibles.');
  exception
    when others then
      if SQLCODE = -20001 then
        dbms_output.put_line('BIEN: Detecta pedido con platos nos disponibles.');
        dbms_output.put_line('Error nro '||SQLCODE);
        dbms_output.put_line('Mensaje '||SQLERRM);
      else
        dbms_output.put_line('MAL: Da error pero no detecta que fallo al hacer la reserva.');
        dbms_output.put_line('Error nro '||SQLCODE);
        dbms_output.put_line('Mensaje '||SQLERRM);
      end if;
  end;
  
     -- Personal de servicio ya tiene 5 pedidos activos y se le asigna otro pedido devuelve el error -20003
     
     begin
      dbms_output.put_line('------------------Test5: Numero de pedidos activos excedido------------------');
      registrar_pedido(1,2,2,1);
      dbms_output.put_line('MAL: No da error al hacer pedido a empleado con 5 pedidos activos.');
  exception
    when others then
      if SQLCODE = -20003 then
        dbms_output.put_line('BIEN: Detecta pedido a empleado con 5 pedidos activos.');
        dbms_output.put_line('Error nro '||SQLCODE);
        dbms_output.put_line('Mensaje '||SQLERRM);
      else
        dbms_output.put_line('MAL: Da error pero no detecta que fallo al hacer la reserva.');
        dbms_output.put_line('Error nro '||SQLCODE);
        dbms_output.put_line('Mensaje '||SQLERRM);
      end if;
  end;
  
     -- ... los que os puedan ocurrir que puedan ser necesarios para comprobar el correcto funcionamiento del procedimiento



  
end;
/


set serveroutput on;
exec test_registrar_pedido;
