-- PREVIEW DATA
SELECT *
FROM PortfolioProject2..NashvilleHousing

--1. STANDARDIZE SaleDate
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

----------------------------------------------

--2. POPULATE PropertyAddress
--Locate NULL values
SELECT *
FROM PortfolioProject2..NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
    ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject2..NashvilleHousing a
JOIN PortfolioProject2..NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL
--Each NULL property address has its value stored in another UniqueID with duplicated ParcelID, we can replace NULL with its duplicated address using ISNULL()

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject2..NashvilleHousing a
JOIN PortfolioProject2..NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

----------------------------------------------

--3. BREAK DOWN Address INTO Address, City, State
--View PropertyAddress
SELECT PropertyAddress
FROM PortfolioProject2..NashvilleHousing

--Split address and city using SUBSTRING()
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS City
FROM PortfolioProject2..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255),
    PropertySplitCity NVARCHAR(255);

--Update Address and City splitted from PropertyAddress to Dataset
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))


--View OwnerAddress
SELECT OwnerAddress
FROM PortfolioProject2..NashvilleHousing

--Split address, city, and state using PARSENAME()
SELECT PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS Address,
PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS City,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS State
FROM PortfolioProject2..NashvilleHousing

--Update into dataset
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),3)),
    OwnerSplitCity = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),2)),
    OwnerSplitState = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),1))


----------------------------------------------

--4. CHANGE Y AND N TO Yes AND No in 'SoldAsVacant'
--Check distinct values
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject2..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END
FROM PortfolioProject2..NashvilleHousing

-- Update into dataset
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END

----------------------------------------------


--5. REMOVE DUPLICATES

WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY 
            ParcelID,
            PropertyAddress,
            SalePrice,
            SaleDate,
            LegalReference
                ORDER BY UniqueID 
    ) row_num
FROM PortfolioProject2..NashvilleHousing)
DELETE 
FROM RowNumCTE
WHERE row_num >1

----------------------------------------------


--6. DELETE UNSUSED COLUMNS
ALTER TABLE PortfolioProject2..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject2..NashvilleHousing
DROP COLUMN SaleDate 