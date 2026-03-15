package trino

import rego.v1

default allow := false

admins := {"admin", "datahub"}

data_catalogs := {"bronze", "silver", "gold"}

# Admins have full access
allow if {
    input.context.identity.user in admins
}

# All authenticated users can execute queries
allow if {
    input.action.operation == "ExecuteQuery"
}

# All authenticated users can access system information
allow if {
    input.action.operation in [
        "AccessCatalog",
        "ShowSchemas",
        "ShowTables",
        "ShowColumns",
        "ShowFunctions",
        "ShowCreateSchema",
        "ShowCreateTable",
    ]
    input.action.resource.catalog.name == "system"
}

# All authenticated users can read the data catalogs (bronze/silver/gold)
allow if {
    input.action.operation == "AccessCatalog"
    input.action.resource.catalog.name in data_catalogs
}

allow if {
    input.action.operation in [
        "ShowSchemas",
        "ShowTables",
        "ShowColumns",
        "ShowCreateSchema",
        "ShowCreateTable",
        "SelectFromColumns",
        "ShowFunctions",
    ]
    input.action.resource.catalog.name in data_catalogs
}

# Allow setting catalog session properties
allow if {
    input.action.operation == "SetCatalogSessionProperty"
}

# Allow table/view read operations for any catalog
allow if {
    input.action.operation in [
        "FilterCatalogs",
        "FilterSchemas",
        "FilterTables",
        "FilterColumns",
    ]
}
