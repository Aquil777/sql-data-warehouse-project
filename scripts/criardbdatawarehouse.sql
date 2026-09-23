-- ver se a db existe
if exists (select 1 from sys.databases where name = 'DataWarehouse')
begin
	alter database DataWarehouse set single_user with rollback immediate;
	drop database DataWarehouse;
end;
go

--criar a db
create database DataWarehouse;

-- criar os schemas
create schema bronze;
create schema silver;
create schema gold;