-----------------------------------------------------------------------------------------
/* SQL Data Cleaning using Nashville Housing Data */
-----------------------------------------------------------------------------------------

select *
from PortfolioProject..NashvilleHousing;

-----------------------------------------------------------------------------------------

--1. Standardize date format for SaleDate column (convert datatype from DATETIME to DATE)

update PortfolioProject..NashvilleHousing
set SaleDate = CONVERT(DATE, SaleDate); 
--successfully updates

select SaleDate
from PortfolioProject..NashvilleHousing;
--but doesn't reflect records with the updated datatype

	--try using other technique--

alter table PortfolioProject..NashvilleHousing
add UpdatedSaleDate DATE;
--successfully adds new column

update PortfolioProject..NashvilleHousing
set UpdatedSaleDate = CONVERT(DATE, SaleDate);
--successfully updates

select SaleDate, UpdatedSaleDate
from PortfolioProject..NashvilleHousing;
--successfully reflects

-----------------------------------------------------------------------------------------

--2. Replace PropertyAddress NULL data

select *
from PortfolioProject..NashvilleHousing
where PropertyAddress is NULL;

select *
from PortfolioProject..NashvilleHousing
order by ParcelID;
--exploring that records with same ParcelID have the same PropertyAddress
--so if we have 2 records with PropertyAddress=NULL in one of those, then we can copy and paste the address from another record with same ParcelID

select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
from NashvilleHousing A
join NashvilleHousing B
	on A.ParcelID = B.ParcelID
	and A.[UniqueID ] != B.[UniqueID ]
where A.PropertyAddress is NULL;
--successfully verified using self-join

update A
set A.PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
from NashvilleHousing A
join NashvilleHousing B
	on A.ParcelID = B.ParcelID
	and A.[UniqueID ] != B.[UniqueID ]
where A.PropertyAddress is NULL;
--successfully updated the records with PropertyAddress=NULL. 
--Can verify that using the 'select self-join' query above, which shouldn't return any records now

-----------------------------------------------------------------------------------------

--3. Breaking out address into individual columns (Address, City, State)

select PropertyAddress
from PortfolioProject..NashvilleHousing
--exploring that PropertyAddress is in the format of 'address, city'

select PropertyAddress, 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1 ) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
	--SUBSTRING(target_string, starting_index, length_of_string) returns a substring from target_string
from PortfolioProject..NashvilleHousing;
--successfully split the PropertyAddress

alter table PortfolioProject..NashvilleHousing
add Address NVARCHAR(255),
	City NVARCHAR(255);
--successfully added 2 new columns

update PortfolioProject..NashvilleHousing
set Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1 );
--successfully updated/added the records

update PortfolioProject..NashvilleHousing
set City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));
--successfully updated/added the records

select *
from PortfolioProject..NashvilleHousing;
--modified table can be verified

select OwnerAddress
from PortfolioProject..NashvilleHousing;
--exploring that OwnerAddress is in the format of 'address, city, state'

select PARSENAME(REPLACE(OwnerAddress,',','.'), 3),
	PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
	PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
	--PARSENAME(target_string, ) returns a substring from target_string. It splits the string with '.' by default.
	--so replace ',' in target_string by '.'
from PortfolioProject..NashvilleHousing;
--successfully split the OwnerAddress

alter table PortfolioProject..NashvilleHousing
add OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255);
--successfully added 3 new columns

update PortfolioProject..NashvilleHousing
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3);
--successfully updated/added the records

update PortfolioProject..NashvilleHousing
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2);
--successfully updated/added the records

update PortfolioProject..NashvilleHousing
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1);
--successfully updated/added the records

select *
from PortfolioProject..NashvilleHousing;
--modified table can be verified

-----------------------------------------------------------------------------------------

--4. Replace 'Y' and 'N' from SoldAsVacant column with 'Yes' and 'No'

select DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) as CountValues
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by CountValues;
--exploring that SoldAsVacant has values of 'Y, N, Yes, No' with their individual counts

select SoldAsVacant,
	case when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
		end
	as NewValues
from PortfolioProject..NashvilleHousing;
--successfully replaced the values

update PortfolioProject..NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
		end;
--successfully updated the records

select *
from PortfolioProject..NashvilleHousing;
--modified table can be verified

-----------------------------------------------------------------------------------------

--5. Remove duplicate records

with RemoveRecCTE as (
	select *,
		ROW_NUMBER() over (
			partition by ParcelID,
				PropertyAddress,
				SalePrice,
				LegalReference
			order by UniqueID
		) as RowNumber
		--ROW_NUMBER() is a ranking function that assigns a sequential rank number to each new record in a partition.
		--When it detects two identical values in the same partition, it assigns different rank numbers to both.
	from PortfolioProject..NashvilleHousing
)
delete from RemoveRecCTE
where RowNumber>1;

-----------------------------------------------------------------------------------------

--6. Delete unused/irrelevant columns

alter table PortfolioProject..NashvilleHousing
drop column SaleDate;
