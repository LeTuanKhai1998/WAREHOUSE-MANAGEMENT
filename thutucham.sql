use QuanLyKhoHangv2
go 


--Dọc dữ liệu rác

--trigger Insert Update Customer
alter trigger trg_Insert_Update_Customer
on Customer
for insert,update
as
if update(Phone) or update(Email)
if exists(select * from inserted i,Customer c
where i.Phone = c.Phone  and i.Id <> c.Id and trim(c.Phone) <> '' and c.IsVisible <>1)
begin
--waitfor delay '00:00:05'
RAISERROR (N'Số điện thoại này đã tồn tại!',0,1)
rollback tran
end
else if exists(select * from inserted i,Customer c
where i.Email = c.Email  and i.Id <> c.Id and trim(c.Email) <> '' and c.IsVisible <>1)
begin
--waitfor delay '00:00:05'
RAISERROR (N'Email này đã tồn tại!',0,1)
rollback tran
end
go


alter proc usp_View_Customer
as
begin
set tran isolation level read uncommitted--lỗi /sửa thành uncommitted
begin tran
 select * from Customer
commit tran  
end
go

--select User
alter proc usp_View_User
as
begin
set tran isolation level read uncommitted--lỗi /sửa thành uncommitted
begin tran
 select * from Users
commit tran  
end
go


exec usp_Insert_Update_Customer 0,N'Khải',null,N'Nữ','q12','','tuankhai@gmail.com','','2019-02-02',N'Đang hoạt động',0,''
exec usp_View_Customer
waitfor delay '00:00:10'
exec usp_View_Customer





--LỖI KHÔNG ĐỌC LẠI ĐƯỢC DỮ LIỆU

--Store Proceduce tổng số nhà cung cấp/tổng số đang hoạt động
alter proc usp_Select_Count_Supplier
as
  begin
declare @Total int
declare @Business int
select @Business = count(*)from Supplier where Status = N'Đang hoạt động' and IsVisible<>1
--waitfor delay '00:00:05'
select @Total = count(*) from Supplier where IsVisible<>1
select @Total  as Total, @Business as Business
  end
go





--lỗi
set tran isolation level read uncommitted begin tran exec usp_Select_Count_Supplier commit tran


--sửa lỗi bóng ma
set tran isolation level Serializable begin tran exec usp_Select_Count_Supplier commit tran












--sửa lỗi không đọc lại được dữ liệu
set tran isolation level repeatable read begin tran exec usp_Select_Count_Supplier commit tran










---Deadlock

create proc Deadlock1
@Id int,
@DisplayName nvarchar(MAX) 
as
begin
	begin tran
exec usp_Insert_Update_Position @Id,@DisplayName
waitfor delay '00:00:10'
exec usp_Insert_Update_Category @Id,@DisplayName
   commit tran
   end 
go


create proc Deadlock2
@Id int,
@DisplayName nvarchar(MAX) 
as
begin
	begin tran
exec usp_Insert_Update_Category @Id,@DisplayName
waitfor delay '00:00:10'
exec usp_Insert_Update_Position @Id,@DisplayName
   commit tran
   end 
go


set tran isolation level Serializable begin tran exec  Deadlock1 1,N'Đồ ăn nhanh' commit tran

set tran isolation level Serializable begin tran exec  Deadlock2 1,N'Đồ ăn nhanh' commit tran



--xử lý deadlock

alter proc DeadlockXuLy1
@Id int,
@DisplayName nvarchar(MAX) 
as  
Begin  
    Begin Tran
 Begin Try
	exec usp_Insert_Update_Position @Id,@DisplayName
	waitfor delay '00:00:10'
	exec usp_Insert_Update_Category @Id,@DisplayName
  Commit tran
  Select 'Transaction Successful' 
 End Try
 Begin Catch
  If(ERROR_NUMBER() = 1205)
  Begin
   Select 'Deadlock. Transaction failed. Please retry'
  End
  Rollback
 End Catch 
End

alter proc DeadlockXuLy2
@Id int,
@DisplayName nvarchar(MAX) 
as  
Begin  
    Begin Tran
 Begin Try
	exec usp_Insert_Update_Category @Id,@DisplayName
	waitfor delay '00:00:10'
	exec usp_Insert_Update_Position @Id,@DisplayName
  Commit tran
  Select 'Transaction Successful' 
 End Try
 Begin Catch
  If(ERROR_NUMBER() = 1205)
  Begin
   Select 'Deadlock. Transaction failed. Please retry'
  End
  Rollback
 End Catch 

End

exec  DeadlockXuLy1 1,N'Đồ ăn nhanh' 

exec  DeadlockXuLy2 1,N'Đồ ăn nhanh' 

------------------



--mất dữ liệu cật nhật


-- Transaction 1
alter proc LostData1
as
begin
--set tran isolation level repeatable read 
Begin Tran
Declare @ItemsInStock int

Select @ItemsInStock = Count
from Object where Id='SP00001'

-- Transaction takes 10 seconds
Waitfor Delay '00:00:10'
Set @ItemsInStock = @ItemsInStock - 1

Update Object 
Set Count = @ItemsInStock where Id='SP00001'

Print @ItemsInStock
Commit Transaction
end

-- Transaction 2
alter proc LostData2
as
begin
set tran isolation level repeatable read 
Begin Tran
Declare @ItemsInStock int

Select @ItemsInStock = Count
from Object where Id='SP00001'

-- Transaction takes 1 second
Waitfor Delay '00:00:1'
Set @ItemsInStock = @ItemsInStock + 2

Update Object
Set Count = @ItemsInStock where Id='SP00001'

Print @ItemsInStock
Commit Transaction
end




exec LostData1

exec LostData2




--View 


create view uv_View_User
as
select * from Users
go
create view uv_View_UserRole
as
select * from UserRole
go
create view uv_View_Supplier
as
select * from Supplier 
go
create view uv_View_Object
as
select * from Object
go
create view uv_View_Input
as
select * from Input
go
create view uv_View_Output
as
select * from Output
go
create view uv_View_Unit
as
select * from Unit
go
create view uv_View_Position
as
select * from Position
go

create view uv_View_InputInfo
as
select * from InputInfo
go
create view uv_View_OutputInfo
as
select * from OutputInfo
go
create view uv_View_Category
as
select * from Category
go
create view uv_View_Customer
as
select * from Customer
go

--proceduce view các bảng
create proc usp_View_User
as
begin
select * from Users
end
go

create proc usp_View_CurrentUserRole
@Id int
as
begin
select * from UserRole where Id =@Id
end
go

create proc usp_View_CurrentUser
@Id int
as
begin
select * from Users where Id =@Id
end
go
exec usp_View_CurrentUser 1


alter proc usp_View_Supplier
as
begin
select * from Supplier 
end
go

create proc usp_View_Object
as
begin
select * from Object
end
go

create proc usp_View_Input
as
begin
select * from Input
end
go
create proc usp_View_Output
as
begin
select * from Output
end
go

create proc usp_View_Unit
as
begin
select * from Unit
end
go

create proc usp_View_Position
as
begin
select * from Position
end
go
exec 
usp_View_Position

create proc usp_View_InputInfo
as
begin
select * from InputInfo
end
go

create proc usp_View_OutputInfo
as
begin
select * from OutputInfo
end
go

create proc usp_View_Category
as
begin
select * from Category
end
go

/*proceduce De Mo Du Lieu Rac*/
--Insert Update Supplier













alter proc usp_Insert_Update_Supplier
@Id int,
@DisplayName nvarchar(MAX),
@Phone nvarchar(20),
@Address nvarchar(MAX),
@Email nvarchar(200),
@MoreInfo nvarchar(MAX),
@ContractDate datetime,
@Status nvarchar(128),
@IsVisible int
as 
begin
  if exists(select * from Supplier with (updlock, serializable)  where id = @Id )
   begin 
update Supplier set DisplayName=@DisplayName,Address=@Address,Phone=@Phone,Email=@Email,MoreInfo=@MoreInfo,ContractDate=@ContractDate,Status=@Status,IsVisible=@IsVisible where Id = @Id  
   end 
  else 
   begin 
insert into Supplier(DisplayName,Address,Phone,Email,MoreInfo,ContractDate,Status,IsVisible) values(@DisplayName,@Address,@Phone,@Email,@MoreInfo,@ContractDate,@Status,@IsVisible)
   end 
end
go









alter proc usp_Insert_Update_Supplier
@Id int,
@DisplayName nvarchar(MAX),
@Phone nvarchar(20),
@Address nvarchar(MAX),
@Email nvarchar(200),
@MoreInfo nvarchar(MAX),
@ContractDate datetime,
@Status nvarchar(128),
@IsVisible int
as 
begin
	--declare @countPhone int = 0
	--declare @countEmail int = 0
	--select @countPhone = count(*) from Supplier c where c.Phone = @Phone  and c.Id <> @Id and trim(c.Phone) <> '' and c.IsVisible <>1
	--select @countEmail= count(*) from Supplier c where c.Email= @Email and c.Id <> @Id and trim(c.Email) <> '' and c.IsVisible <>1
  if exists(select * from Supplier with (updlock, serializable)  where id = @Id )
   begin 
    --begin tran
update Supplier set DisplayName=@DisplayName,Address=@Address,Phone=@Phone,Email=@Email,MoreInfo=@MoreInfo,ContractDate=@ContractDate,Status=@Status,IsVisible=@IsVisible where Id = @Id  
--     if (@countPhone <> 0)
--      begin
----waitfor delay '00:00:10'
--RAISERROR (N'Số điện thoại này đã tồn tại!',0,1)
--rollback tran
--      end
--     else if (@countEmail <> 0 )
--      begin
----waitfor delay '00:00:10'
--RAISERROR (N'Email này đã tồn tại!',0,1)
--rollback tran
--      end
--	 else commit tran
   end 
  else 
   begin 
    --begin tran 
insert into Supplier(DisplayName,Address,Phone,Email,MoreInfo,ContractDate,Status,IsVisible) values(@DisplayName,@Address,@Phone,@Email,@MoreInfo,@ContractDate,@Status,@IsVisible)
--	 if (@countPhone <> 0)
--      begin
----waitfor delay '00:00:10'
--RAISERROR (N'Số điện thoại này đã tồn tại!',0,1)
--rollback tran
--      end
--	 else if (@countEmail <> 0 )
--      begin
----waitfor delay '00:00:10'
--RAISERROR (N'Email này đã tồn tại!',0,1)
--rollback tran
--      end
--	else commit tran
   end 
end
go

--exec usp_Insert_Update_Supplier 0,N'Khôi','0123456789','q12','   ','','2019-02-02',N'Đang hoạt động',0

----delete Supplier where Id = 12
--set tran isolation level read committed
--begin tran
--exec usp_View_Supplier
--commit tran   

--exec usp_Delete_Supplier 33

--Insert Update Customer
alter proc usp_Insert_Update_Customer
@Id int,
@DisplayName nvarchar(MAX),
@BirthDay datetime,
@Sex nvarchar(10),
@Address nvarchar(MAX),
@Phone nvarchar(20),
@Email nvarchar(200),
@MoreInfo nvarchar(MAX),
@ContractDate datetime,
@Status nvarchar(128),
@IsVisible int,
@LinkImage nvarchar(MAX)
as 
begin
	--declare @countPhone int = 0
	--declare @countEmail int = 0
	--select @countPhone = count(*) from Customer c where c.Phone = @Phone  and c.Id <> @Id
	--select @countEmail= count(*) from Customer c where c.Email= @Email and c.Id <> @Id
  if exists(select * from Customer with (updlock, serializable)  where id = @Id )
   begin 
    --begin tran
update Customer set DisplayName=@DisplayName,BirthDay=@BirthDay,Sex=@Sex,Address=@Address,Phone=@Phone,Email=@Email,MoreInfo=@MoreInfo,ContractDate=@ContractDate,Status=@Status,IsVisible=@IsVisible,LinkImage=@LinkImage  where Id = @Id  
--     if (@countPhone <> 0)
--      begin
----waitfor delay '00:00:10'
--RAISERROR (N'Số điện thoại này đã tồn tại!',0,1)
--rollback tran
--      end
--     else if (@countEmail <> 0 )
--      begin
----waitfor delay '00:00:10'
--RAISERROR (N'Email này đã tồn tại!',0,1)
--rollback tran
--      end
--	 else commit tran
   end 
  else 
   begin 
    --begin tran 
insert into Customer(DisplayName,BirthDay,Sex,Address,Phone,Email,MoreInfo,ContractDate,Status,IsVisible,LinkImage )  values(@DisplayName,@BirthDay,@Sex,@Address,@Phone,@Email,@MoreInfo,@ContractDate,@Status,@IsVisible,@LinkImage)
--	 if (@countPhone <> 0)
--      begin
----waitfor delay '00:00:10'
--RAISERROR (N'Số điện thoại này đã tồn tại!',0,1)
--rollback tran
--      end
--	 else if (@countEmail <> 0 )
--      begin
----waitfor delay '00:00:10'
--RAISERROR (N'Email này đã tồn tại!',0,1)
--rollback tran
--      end
--	else commit tran
   end 
end
go       

exec usp_Insert_Update_Customer 1020,N'Khôi',null,N'Nữ','q12','01234562','tongan@gmail.com','','2019-02-02',N'Đang hoạt động',0,''

--delete Customer Id where = 1017
set tran isolation level read uncommitted
begin tran
exec usp_View_Customer
commit tran   



--Insert Update Object
alter proc usp_Insert_Update_Object
@Id nvarchar(128),
@DisplayName varchar(MAX),
@IdUnit int,
@IdCategory int,        
@InputPrice float,
@OutputPrice float,
@Count int,
@IdPosition int,
@LinkImage nvarchar(128),
@Status nvarchar(128),
@IsVisible int
as 
begin
 begin tran 
  if exists(select * from Object with (updlock, serializable)  where id = @Id )
   begin 
Update Object set DisplayName = @DisplayName , IdUnit = @IdUnit, IdCategory = @IdCategory ,InputPrice = @InputPrice, OutputPrice = @OutputPrice, Count = @Count, IdPosition = @IdPosition,LinkImage = @LinkImage,Status = @Status,IsVisible = @IsVisible  where Id = @Id
   end 
  else 
  begin
  declare @IdInsert nvarchar(128) = ''
if((select count(*) from Object)=0)
  begin
set @IdInsert = 'SP00001'
  end
else
  begin
  declare @loop int = 0
  declare @index int = 0
  declare @idTemp nvarchar(128)
SELECT TOP 1 @idTemp = Id FROM Object ORDER BY Id DESC
SET @idTemp = SUBSTRING(@idTemp, 3, 5) 
set @loop = 5 - len(CAST(@idTemp AS int))
set @index = CAST(@idTemp AS int)+1;
set @IdInsert = 'SP'
if CAST(SUBSTRING(@idTemp, 4, 5)  AS int) = 9
  begin
set @loop -= 1
  end
  while @loop > 0
  begin
set @IdInsert += '0'
set @loop -=1
  end
set @IdInsert += CAST(@index AS nvarchar)
  end
insert into Object(Id,DisplayName,IdUnit,IdCategory,InputPrice,OutputPrice, Count,IdPosition,LinkImage,Status,IsVisible) values(@IdInsert,@DisplayName,@IdUnit,@IdCategory,@InputPrice,@OutputPrice,@Count,@IdPosition,@LinkImage,@Status,@IsVisible)
select @IdInsert
   end 
 commit tran
end
go

exec usp_Insert_Update_Object '',N'khải hehe',null,1,5000,6000,0,null,'IMG_SP00006.png','Cho phép',0

delete Object where Id = 'SP00007'
exec usp_View_Object

create proc usp_Check_DisplayName_Exist_Object
@DisplayName nvarchar(MAX),
@Id nvarchar(128)
 as 
 begin
select count(*) from Object where DisplayName = @DisplayName and Id <> @Id
 end
go
--exec usp_Check_DisplayName_Exist_Object test,'SP00007'

--Delete Object
alter proc usp_Delete_Object
@Id nvarchar(128)
as 
begin
 begin tran 
  if( exists(select * from OutputInfo with (updlock, serializable) inner join Object  on OutputInfo.IdObject = Object.Id where Object.Id = @Id ) 
  or exists(select * from InputInfo with (updlock, serializable) inner join Object  on InputInfo.IdObject = Object.Id where Object.Id = @Id ) )
   begin 
Update Object set IsVisible = 1 where Id = @Id
   end 
  else 
   begin 
delete from Object where Id = @Id
   end 
 commit tran
end
go

--exec usp_Delete_Object 'SP00007'




--Delete User
create proc usp_Delete_User
@Id nvarchar(128)
as 
begin
 begin tran 
  if( exists(select * from Output with (updlock, serializable) inner join Users  on Output.IdUser = Users.Id where Users.Id = @Id ) 
  or exists(select * from Input with (updlock, serializable) inner join Users  on Input.IdUser = Users.Id where Users.Id = @Id ) )
   begin 
Update Users set IsVisible = 1 where Id = @Id
   end 
  else 
   begin 
delete from Users where Id = @Id
   end 
 commit tran
end
go

--exec usp_Delete_User 1
--exec usp_View_User

--Delete Supplier
alter proc usp_Delete_Supplier
@Id nvarchar(128)
as 
begin
 begin tran 
  if exists(select * from Input  inner join Supplier  on Input.IdSupplier = Supplier.Id where Supplier.Id = @Id) 
   begin 
Update Supplier set IsVisible = 1 where Id = @Id
Update Input set IdSupplier = null where IdSupplier = @Id and Status = N'Phiếu tạm'
   end 
  else 
   begin 
delete from Supplier where Id = @Id
   end 
 commit tran
end
go

--exec usp_Delete_Supplier 20
--exec usp_View_Supplier
--exec usp_View_Input

--Delete Customer
create proc usp_Delete_Customer
@Id nvarchar(128)
as 
begin
 begin tran 
  if exists(select * from Output with (updlock, serializable) inner join Customer  on Output.IdCustomer = Customer.Id where Customer.Id = @Id) 
   begin 
Update Customer set IsVisible = 1 where Id = @Id
   end 
  else 
   begin 
delete from Customer where Id = @Id
   end 
 commit tran
end
go

---Delete Catgory
alter proc usp_Delete_Category
@Id int
as 
begin
 begin tran 
  if exists(select * from Object with (updlock, serializable) inner join Category  on Object.IdCategory= Category.Id where Category.Id = @Id and Object.IsVisible = 0) 
   begin 
RAISERROR (N'Loại hàng này đã được sử dụng trong các hàng hóa!',0,1)
rollback tran
   end 
  else 
   begin 
Update Object set IdCategory = null where IdCategory = @Id and IsVisible = 1
delete from Category where Id = @Id
   end 
 commit tran
end
go

exec usp_Delete_Category 26


---Delete Position
alter proc usp_Delete_Position
@Id int
as 
begin
 begin tran 
  if exists(select * from Object with (updlock, serializable) inner join Position on Object.IdCategory= Position.Id where Position.Id = @Id and IsVisible = 0) 
   begin 
RAISERROR (N'Vị trí này đã được sử dụng trong các hàng hóa!',0,1)
rollback tran
   end 
  else 
   begin 
Update Object set IdPosition= null where IdPosition = @Id and IsVisible = 1
delete from Position where Id = @Id
   end 
 commit tran
end
go


---Delete Catgory
alter proc usp_Delete_Unit
@Id int
as 
begin
 begin tran 
  if exists(select * from Object with (updlock, serializable) inner join Unit  on Object.IdCategory= Unit.Id where Unit.Id = @Id and IsVisible = 0) 
   begin 
RAISERROR (N'Đơn vị tính này đã được sử dụng trong các hàng hóa!',0,1)
rollback tran
   end 
  else 
   begin 
Update Object set IdUnit= null where IdUnit= @Id and IsVisible = 1
delete from Unit where Id = @Id
   end 
 commit tran
end
go



--Update Status Object
create proc usp_Update_Status_Object
@Id nvarchar(128),
@Status nvarchar(128)
as 
begin
Update Object set Status  = @Status where Id = @Id
end
go



--Update RolePermision 
create proc usp_Update_RolePermision_UserRole
@Id nvarchar(128),
@RolePermision nvarchar(128)
as 
begin
Update UserRole set RolePermision = @RolePermision where Id = @Id
end
go




--Insert Update Input
alter proc usp_Insert_Update_Input
@Id nvarchar(128),
@IdUser int,
@IdSupplier int,        
@DateInput datetime,
@Discount float,
@Payment nvarchar(128),
@TotalPrice float,
@Note nvarchar(MAX),
@Status nvarchar(128),
@TotalObject int,
@TotalQuantity int   
as 
begin
 begin tran 
  if exists(select * from Input with (updlock, serializable)  where id = @Id )
   begin 
update Input set IdUser = @IdUser, IdSupplier = @IdSupplier,DateInput = @DateInput,Discount = @Discount,Payment = @Payment,TotalPrice = @TotalPrice,Note = @Note,Status = @Status,TotalObject = @TotalObject,TotalQuantity = @TotalQuantity where Id = @Id
   end 
  else 
  begin
  declare @IdInsert nvarchar(128) = ''
if((select count(*) from Input)=0)
  begin
set @IdInsert = 'PN00001'
  end
else
  begin
  declare @loop int = 0
  declare @index int = 0
  declare @idTemp nvarchar(128)
SELECT TOP 1 @idTemp = Id FROM Input ORDER BY Id DESC
SET @idTemp = SUBSTRING(@idTemp, 3, 5) 
set @loop = 5 - len(CAST(@idTemp AS int))
set @index = CAST(@idTemp AS int)+1;
set @IdInsert = 'PN'
if CAST(SUBSTRING(@idTemp, 4, 5)  AS int) = 9
  begin
set @loop -= 1
  end
  while @loop > 0
  begin
set @IdInsert += '0'
set @loop -=1
  end
set @IdInsert += CAST(@index AS nvarchar)
  end
insert into Input(Id,IdUser,IdSupplier,DateInput,Discount,Payment,TotalPrice,Note,Status,TotalObject,TotalQuantity) values(@IdInsert,@IdUser,@IdSupplier,@DateInput,@Discount,@Payment,@TotalPrice,@Note,@Status,@TotalObject,@TotalQuantity)
select @IdInsert
   end 
 commit tran
end
go


--exec usp_Insert_Update_Input '',2,1,'2019-02-02',0,N'Tiền',10000,'',N'Đã nhập hàng',1,10

--delete Input where Id = 'PN00012'

--set tran isolation level read uncommitted
--begin tran
--exec usp_View_Input
--commit tran

--exec usp_View_Input
--exec usp_View_InputInfo
--exec usp_View_Object

use QuanLyKhoHangv2
go
--Insert Update InputInfo
create proc usp_Insert_Update_InputInfo
@IdInput nvarchar(128),
@IdObject nvarchar(128),
@Price float, 
@Quantity  int,
@Discount float,
@IdUnit int
as 
begin
 begin tran 
  if exists(select * from InputInfo with (updlock, serializable)  where IdInput = @IdInput and IdObject = @IdObject)
   begin 
update InputInfo set Price = @Price,Quantity= @Quantity,Discount = @Discount  where IdInput = @IdInput and IdObject = @IdObject
   end 
  else 
   begin 
insert into InputInfo(IdInput,IdObject,Price,Quantity,Discount)  values(@IdInput,@IdObject,@Price,@Quantity,@Discount)
   end 
   declare @Status nvarchar(128) = ''
   select @Status = Status  from Input where Id = @IdInput
   if(@Status = N'Đã nhập hàng')
   begin
   declare @Count int = 0
   select @Count = @Quantity + Count from Object where Id = @IdObject
   declare @InputPrice float = 0
   select @InputPrice =( @Quantity*@Price + Count*InputPrice)/(@Quantity+Count) from Object where Id = @IdObject
   update Object set Count = @Count,InputPrice = @InputPrice,IdUnit = @IdUnit where Id = @IdObject
   end
 commit tran
end
go 



--Insert Update Output
alter proc usp_Insert_Output
@IdUser int,
@IdCustomer int,        
@DateOutput datetime,
@Discount float,
@Payment nvarchar(128),
@TotalPrice float,
@Note nvarchar(MAX),
@Status nvarchar(128)   
as 
begin 
  declare @IdInsert nvarchar(128) = ''
if((select count(*) from Output)=0)
  begin
set @IdInsert = 'HD00001'
  end
else
  begin
  declare @loop int = 0
  declare @index int = 0
  declare @idTemp nvarchar(128)
SELECT TOP 1 @idTemp = Id FROM Output ORDER BY Id DESC
SET @idTemp = SUBSTRING(@idTemp, 3, 5) 
set @loop = 5 - len(CAST(@idTemp AS int))
set @index = CAST(@idTemp AS int)+1;
set @IdInsert = 'HD'
if CAST(SUBSTRING(@idTemp, 4, 5)  AS int) = 9
  begin
set @loop -= 1
  end
  while @loop > 0
  begin
set @IdInsert += '0'
set @loop -=1
  end
set @IdInsert += CAST(@index AS nvarchar)
  end
insert into Output(Id,IdUser,IdCustomer,DateOutput,Discount,Payment,TotalPrice,Note,Status)  values(@IdInsert,@IdUser,@IdCustomer,@DateOutput,@Discount,@Payment,@TotalPrice,@Note,@Status)
select @IdInsert
end
go 



--exec usp_Insert_Output 2,1,'2019-02-02',0,N'Tiền mặt',10000,'',N'Đã nhập hàng'
--delete Output where Id = 'HD00020'

--set tran isolation level read uncommitted
--begin tran
--exec usp_View_Output
--commit tran

--Insert Update OutputInfo
alter proc usp_Insert_OutputInfo
@IdOutput nvarchar(128),
@IdObject nvarchar(128),
@Price float, 
@Quantity  int,
@Discount float
as 
begin
 begin tran 
insert into OutputInfo(IdOutput,IdObject,Price,Quantity,Discount) values(@IdOutput,@IdObject,@Price,@Quantity,@Discount)
declare @Count int = 0
select @Count = -@Quantity + Count from Object where Id = @IdObject
   if(@Count<0)
   begin
   --declare @string nvarchar(MAX) = ''
   --set @string = N'Số lượng '+  DisplayName from Object where Id = @IdObject +' không quá số lượng tồn!'
RAISERROR (N'Số lượng không quá số lượng tồn!',0,1)
rollback tran
	end
	else
update Object set Count = @Count where Id = @IdObject
 commit tran
end
go 
--exec usp_Insert_OutputInfo 'HD00006','SP00006',10000,1,0

--exec usp_View_Output
--exec usp_View_OutputInfo
--exec usp_View_Object

--Insert Update Category
alter proc usp_Insert_Update_Category
@Id int,
@DisplayName nvarchar(MAX) 
as 
begin
--if exists(select * from Category with (updlock, serializable)  where id <> @Id and UPPER(DisplayName) = UPPER(@DisplayName) )
--  begin
--RAISERROR (N'Tên đã tồn tại!',0,1)
--  end
--else 
  begin
 if exists(select * from Category with (updlock, serializable)  where id = @Id )
  begin 
  --select * from Category
  --waitfor delay '00:00:5'
update Category set DisplayName=@DisplayName where Id = @Id  
   end 
 else 
   begin 
  --   select * from Category
  --waitfor delay '00:00:5'
insert into Category(DisplayName)  values(@DisplayName)
   end
   end 
end
go



exec usp_Insert_Update_Category 1,N'Đồ ăn không nhanh'


--Insert Update Position
create proc usp_Insert_Update_Position
@Id int,
@DisplayName nvarchar(MAX) 
as 
begin
--if exists(select * from Position with (updlock, serializable)  where id <> @Id and UPPER(DisplayName) = UPPER(@DisplayName) )
--  begin
--RAISERROR (N'Tên đã tồn tại!',0,1)
--  end
--else 
  begin
 if exists(select * from Position with (updlock, serializable)  where id = @Id )
  begin 
update Position set DisplayName=@DisplayName where Id = @Id  
   end 
 else 
   begin 
insert into Position(DisplayName)  values(@DisplayName)
   end
   end 
end
go

--Insert Update Unit
create proc usp_Insert_Update_Unit
@Id int,
@DisplayName nvarchar(MAX) 
as 
begin
--if exists(select * from Unit with (updlock, serializable)  where id <> @Id and UPPER(DisplayName) = UPPER(@DisplayName) )
--  begin
--RAISERROR (N'Tên đã tồn tại!',0,1)
--  end
--else 
  begin
 if exists(select * from Unit with (updlock, serializable)  where id = @Id )
  begin 
update Unit set DisplayName=@DisplayName where Id = @Id  
   end 
 else 
   begin 
insert into Unit(DisplayName)  values(@DisplayName)
   end
   end 
end
go



--exec usp_Insert_Update_Category 0,N'Mỹ phẩm'
--delete Category where Id = 7
--exec usp_View_Category

--Update Status Output
create proc usp_Update_Status_Output
@Id nvarchar(128),
@Status nvarchar(128)
as 
begin
Update Output set Status = @Status where Id = @Id
end
go 

--Update Note Output
create proc usp_Update_Note_Output
@Id nvarchar(128),
@Note nvarchar(MAX)
as 
begin
Update Output set Note = @Note where Id = @Id
end
go 


--Update Status Intput
create proc usp_Update_Status_Input
@Id nvarchar(128),
@Status nvarchar(128)
as 
begin
Update Input set Status = @Status where Id = @Id
end
go 

--Update Note Input
create proc usp_Update_Note_Input
@Id nvarchar(128),
@Note nvarchar(MAX)
as 
begin
Update Input set Note = @Note where Id = @Id
end
go 
--exec usp_Update_Note_Input 'PN00009','hehe'
--exec usp_View_InputInfo

--exec usp_Update_Status_Input 'd','d'

--/*trigger*/
--trigger Insert Update Category
alter trigger trg_Insert_Update_Category
on Category
for insert,update
as
if update(DisplayName)
if exists(select * from inserted i,Category c
where UPPER(i.DisplayName) = UPPER(c.DisplayName) and i.Id <> c.Id)
begin
RAISERROR (N'Tên này đã tồn tại!',0,1)
rollback tran
end

--trigger Insert Update Position
create trigger trg_Insert_Update_Position
on Position
for insert,update
as
if update(DisplayName)
if exists(select * from inserted i,Position c
where UPPER(i.DisplayName) = UPPER(c.DisplayName) and i.Id <> c.Id)
begin
RAISERROR (N'Tên này đã tồn tại!',0,1)
rollback tran
end
go





--trigger Insert Update User
alter trigger trg_Insert_Update_User
on Users
for insert,update
as
if update(Phone) or update(Email) or update(UserName)
if exists(select * from inserted i,Users c
where i.Phone = c.Phone  and i.Id <> c.Id and trim(c.Phone) <> '' and c.IsVisible <>1)
begin
--waitfor delay '00:00:10'
RAISERROR (N'Số điện thoại này đã tồn tại!',0,1)
rollback tran
end
else if exists(select * from inserted i,Users c
where i.Email = c.Email  and i.Id <> c.Id and trim(c.Email) <> '' and c.IsVisible <>1)
begin
--waitfor delay '00:00:10'
RAISERROR (N'Email này đã tồn tại!',0,1)
rollback tran
end
else if exists(select * from inserted i,Users c
where i.UserName = c.UserName  and i.Id <> c.Id and trim(c.UserName) <> '' and c.IsVisible <>1)
begin
--waitfor delay '00:00:10'
RAISERROR (N'Tên đăng nhập này đã tồn tại!',0,1)
rollback tran
end
go

--trigger Insert Update Unit
create trigger trg_Insert_Update_Unit
on Unit
for insert,update
as
if update(DisplayName)
if exists(select * from inserted i,Unit c
where UPPER(i.DisplayName) = UPPER(c.DisplayName) and i.Id <> c.Id)
begin
RAISERROR (N'Tên này đã tồn tại!',0,1)
rollback tran
end
go

--exec usp_View_Category



--trigger Insert Update Supplier
alter trigger trg_Insert_Update_Supplier
on Supplier
for insert,update
as
if update(Phone) or update(Email)
if exists(select * from inserted i,Supplier c
where i.Phone = c.Phone  and i.Id <> c.Id and trim(c.Phone) <> '' and c.IsVisible <>1)
begin
waitfor delay '00:00:10'
RAISERROR (N'Số điện thoại này đã tồn tại!',0,1)
rollback tran
end
else if exists(select * from inserted i,Supplier c
where i.Email = c.Email  and i.Id <> c.Id and trim(c.Email) <> '' and c.IsVisible <>1)
begin
waitfor delay '00:00:10'
RAISERROR (N'Email này đã tồn tại!',0,1)
rollback tran
end
go



        
        







create proc usp_Update_Customer
@Id int,
@DisplayName nvarchar(MAX),
@BirthDay datetime,
@Sex nvarchar(10),
@Address nvarchar(MAX),
@Phone nvarchar(20),
@Email nvarchar(200),
@MoreInfo nvarchar(MAX),
@ContractDate datetime,
@Status nvarchar(128),
@IsVisible int,
@LinkImage nvarchar(MAX)
as
begin
update Customer set DisplayName=@DisplayName,BirthDay=@BirthDay,Sex=@Sex,Address=@Address,Phone=@Phone,Email=@Email,MoreInfo=@MoreInfo,ContractDate=@ContractDate,Status=@Status,IsVisible=@IsVisible,LinkImage=@LinkImage where Id = @Id
end
go
create proc usp_Update_Status_Customer
@Id int,
@Status nvarchar(128)
as
begin
update Customer set Status=@Status where Id = @Id
end
go


create proc usp_Update_Status_Supplier
@Id int,
@Status nvarchar(128)
as
begin
update Supplier set Status=@Status where Id = @Id
end
go

usp_View_Supplier

create proc usp_Update_Status_User
@Id int,
@Status nvarchar(128)
as
begin
update Users set Status=@Status where Id = @Id
end
go


go
create proc usp_Insert_Customer
@DisplayName nvarchar(MAX),
@BirthDay datetime,
@Sex nvarchar(10),
@Address nvarchar(MAX),
@Phone nvarchar(20),
@Email nvarchar(200),
@MoreInfo nvarchar(MAX),
@ContractDate datetime,
@Status nvarchar(128),
@IsVisible int,
@LinkImage nvarchar(MAX)
as
begin
insert into Customer(DisplayName,BirthDay,Sex,Address,Phone,Email,MoreInfo,ContractDate,Status,IsVisible,LinkImage )
 values(@DisplayName,@BirthDay,@Sex,@Address,@Phone,@Email,@MoreInfo,@ContractDate,@Status,@IsVisible,@LinkImage)
end
go

--Hàm người dùng Function
--Check Login
alter function uf_Check_Login
(@UserName nvarchar(100),@Password nvarchar(MAX)) returns Table
As
Return
(Select *
From Users
Where Upper(UserName) = Upper(@UserName)
and Upper(Users.Password) = Upper(@Password) and IsVisible = 0 and Status = N'Đang hoạt động')
Go

--Select * from uf_Check_Login('admin','db69fc039dcbd2962cb4d28f5891aae1')


--Lấy ds Thẻ kho hàng hóa
alter function uf_Select_Deal (@Id nvarchar(128))
returns @Deal table( id nvarchar(128),method nvarchar(128),date Datetime, price float,count int,stock int) 
as begin
insert into @Deal select Id,N'Nhập hàng',DateInput,InputPrice,Quantity,Stock  from InputInfo  join Input on IdInput = Id
where IdObject = @Id
insert into @Deal select Id,N'Xuất hàng',DateOutput,InputPrice,Quantity,Stock  from OutputInfo  join Output on IdOutput = Id
where IdObject = @Id
return
end

--select * from uf_Select_Deal('SP00001') order by date


--hàm người dùng
--Tính số phiếu nhập,tổng tiền từ ngày A-B
alter function uf_Select_Revenue_Input (@dateIn date,@dateOut date) returns @Revenue table
( CoutnIn int, TotalIn float)
as begin
insert into @Revenue select count(*), sum(A.TotalPrice-A.Discount) from Input A 
where CONVERT(date, A.DateInput) between @dateIn and @dateOut
and A.Status <> N'Phiếu tạm' and A.Status <> N'Đã hủy'
return
end


--select * from uf_Select_Revenue_Input('2019-05-29 00:00:00','2019-05-29 23:59:59')


--Tính số hóa đơn,tổng tiền từ ngày A-B
alter function uf_Select_Revenue_Output (@dateIn datetime,@dateOut datetime) returns @Revenue table
( CoutnIn int, TotalIn float)
as begin

insert into @Revenue select count(*), sum(A.TotalPrice) from Output A where A.DateOutput between @dateIn and @dateOut
and A.Status <>N'Đã hủy'
return

end

select * from uf_Select_Revenue_Output('2019-05-28 00:00:00','2019-05-28 23:59:59')

--Tính Tổng Doanh thu theo ngày
ALTER function [dbo].[uf_Select_Revenue] (@dateIn date,@dateOut date) returns @Revenue table
(day Date,Sales float)
as begin
insert into @Revenue 
select CONVERT(date, DateOutput),sum(TotalPrice)  
from  Output 
where CONVERT(date, DateOutput) between @dateIn and @dateOut
and Status  <> N'Đã hủy'
group by CONVERT(date, DateOutput)
return
end


	--select * from uf_Select_Revenue('2019-05-25','2019-05-30')


go




exec usp_Select_Count_Supplier



--Insert Update UserRole
create proc usp_Insert_UserRole
@Id int,
@DisplayName nvarchar(MAX),
@RolePermision nvarchar(MAX)
as 
begin
  if exists(select * from UserRole with (updlock, serializable)  where id = @Id )
   begin 
update UserRole set DisplayName=@DisplayName,RolePermision=@RolePermision  where Id = @Id  
   end 
  else 
   begin 
insert into UserRole(DisplayName,RolePermision)
  values(@DisplayName,@RolePermision)
   end 
end
go 


--Insert Update User
alter proc usp_Insert_Update_User
@Id int,
@DisplayName nvarchar(MAX),
@BirthDay datetime,
@Sex nvarchar(10),
@Address nvarchar(MAX),
@Phone nvarchar(20),
@Email nvarchar(200),
@MoreInfo nvarchar(MAX),
@UserName nvarchar(100),
@Password nvarchar(MAX),
@IdRole int,
@Status nvarchar(128),
@IsVisible int
as 
begin
  if exists(select * from Users with (updlock, serializable)  where id = @Id )
   begin 
update Users set DisplayName=@DisplayName,BirthDay=@BirthDay,Sex=@Sex,Address=@Address
,Phone=@Phone,Email=@Email,MoreInfo=@MoreInfo,UserName = @UserName,Password= @Password, IdRole=@IdRole,Status=@Status
,IsVisible=@IsVisible  where Id = @Id  
   end 
  else 
   begin 
insert into Users(DisplayName,BirthDay,Sex,Address,Phone,Email,MoreInfo,UserName,Password,IdRole,Status,IsVisible)
  values(@DisplayName,@BirthDay,@Sex,@Address,@Phone,@Email,@MoreInfo,@UserName,@Password,@IdRole,@Status,@IsVisible)
   end 
end
go 

exec usp_Insert_Update_User 6,N'khỉ','2019-02-02',N'Nam',N'','012333556',N'',N'',N'khai1234',N'123',1,N'Đang hoạt động',0

select* from uv_View_User




--Insert Update Customer
create proc usp_Insert_Update_Customer
@Id int,
@DisplayName nvarchar(MAX),
@BirthDay datetime,
@Sex nvarchar(10),
@Address nvarchar(MAX),
@Phone nvarchar(20),
@Email nvarchar(200),
@MoreInfo nvarchar(MAX),
@ContractDate datetime,
@Status nvarchar(128),
@IsVisible int,
@LinkImage nvarchar(MAX)
as 
begin
  if exists(select * from Customer with (updlock, serializable)  where id = @Id )
   begin 
update Customer set DisplayName=@DisplayName,BirthDay=@BirthDay,Sex=@Sex,Address=@Address
,Phone=@Phone,Email=@Email,MoreInfo=@MoreInfo,ContractDate=@ContractDate,Status=@Status
,IsVisible=@IsVisible,LinkImage=@LinkImage  where Id = @Id  
   end 
  else 
   begin 
insert into Customer(DisplayName,BirthDay,Sex,Address,Phone,Email,MoreInfo,ContractDate,Status,IsVisible,LinkImage )
  values(@DisplayName,@BirthDay,@Sex,@Address,@Phone,@Email,@MoreInfo,@ContractDate,@Status,@IsVisible,@LinkImage)
   end 
end
go       