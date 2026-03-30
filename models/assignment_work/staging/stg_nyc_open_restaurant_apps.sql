-- Clean and standardize Open Restaurant Applications data
-- One row per application

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- Keep all columns except ones we transform
        * EXCEPT (
            globalid,
            objectid,
            time_of_submission,
            borough,
            zip,
            latitude,
            longitude
        ),

        -- Identifiers (choose one as primary)
        CAST(globalid AS STRING) AS application_id,
        CAST(objectid AS STRING) AS object_id,

        -- Timestamp
        CAST(time_of_submission AS TIMESTAMP) AS submitted_at,

        -- Standardize borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Clean ZIP codes
        CASE
            WHEN UPPER(TRIM(zip)) IN ('N/A', 'NA', '') THEN NULL
            WHEN LENGTH(TRIM(zip)) = 5 THEN TRIM(zip)
            WHEN LENGTH(TRIM(zip)) = 10 
                 AND REGEXP_CONTAINS(zip, r'^\d{5}-\d{4}')
                THEN zip
            ELSE NULL
        END AS zip,

        -- Coordinates
        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,

        -- Normalize text fields (optional but nice)
        UPPER(TRIM(restaurant_name)) AS restaurant_name,
        UPPER(TRIM(legal_business_name)) AS legal_business_name,
        UPPER(TRIM(doing_business_as_dba)) AS dba_name,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Basic filtering (lighter than 311)
    WHERE globalid IS NOT NULL
    AND time_of_submission IS NOT NULL

    -- Deduplication (VERY important for this dataset)
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY globalid
        ORDER BY time_of_submission DESC
    ) = 1
)

SELECT * FROM cleaned