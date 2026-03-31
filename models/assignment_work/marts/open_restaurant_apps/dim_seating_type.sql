-- Seating type dimension for open restaurant seating applications
WITH seating_types AS (
    SELECT DISTINCT
        seating_interest_sidewalk AS seating_interest,

        -- Convert approval columns to boolean
        CASE 
            WHEN approved_for_sidewalk_seating = 'Y' THEN TRUE
            ELSE FALSE
        END AS approved_for_sidewalk,

        CASE 
            WHEN approved_for_roadway_seating = 'Y' THEN TRUE
            ELSE FALSE
        END AS approved_for_roadway

    FROM {{ ref('stg_nyc_open_restaurant_apps') }}  -- your staging table
    WHERE seating_interest_sidewalk IS NOT NULL
),

seating_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'seating_interest',
            'approved_for_sidewalk',
            'approved_for_roadway'
        ]) }} AS seating_type_key,
        seating_interest,
        approved_for_sidewalk,
        approved_for_roadway
    FROM seating_types
)

SELECT * 
FROM seating_dimension