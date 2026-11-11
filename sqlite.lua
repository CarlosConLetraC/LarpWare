-- sqlite.lua
local ffi = require("ffi")

ffi.cdef[[
    typedef struct sqlite3 sqlite3;
    typedef struct sqlite3_stmt sqlite3_stmt;

    int sqlite3_open(const char *filename, sqlite3 **ppDb);
    int sqlite3_close(sqlite3 *pDb);
    const char *sqlite3_errmsg(sqlite3 *pDb);
    int sqlite3_exec(sqlite3*, const char *sql, int (*callback)(void*,int,char**,char**), void *, char **errmsg);
    
    int sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail);
    int sqlite3_step(sqlite3_stmt *pStmt);
    int sqlite3_column_count(sqlite3_stmt *pStmt);
    const char *sqlite3_column_name(sqlite3_stmt *pStmt, int N);
    int sqlite3_column_type(sqlite3_stmt *pStmt, int iCol);
    const char *sqlite3_column_text(sqlite3_stmt *pStmt, int iCol);
    double sqlite3_column_double(sqlite3_stmt *pStmt, int iCol);
    long long sqlite3_column_int64(sqlite3_stmt *pStmt, int iCol);
    
    // FUNCIONES BLOB NECESARIAS:
    const void *sqlite3_column_blob(sqlite3_stmt *pStmt, int iCol);
    int sqlite3_column_bytes(sqlite3_stmt *pStmt, int iCol);
    int sqlite3_finalize(sqlite3_stmt *pStmt);
]]

local libsqlite = ffi.load("sqlite3")
local SQLite = {}
SQLite.__index = SQLite

function SQLite.open(filename)
    local db_pp = ffi.new("sqlite3*[1]")
    local rc = libsqlite.sqlite3_open(filename, db_pp)
    if rc ~= 0 then
        local err = ffi.string(libsqlite.sqlite3_errmsg(db_pp[0]))
        error(string.format("[SQLite Error] No se pudo abrir '%s': %s", filename, err))
    end
    return setmetatable({ db = db_pp[0], path = filename }, SQLite)
end

function SQLite:close()
    if self.db then
        libsqlite.sqlite3_close(self.db)
        self.db = nil
    end
end

function SQLite:exec(sql)
    local errmsg_pp = ffi.new("char*[1]")
    local rc = libsqlite.sqlite3_exec(self.db, sql, nil, nil, errmsg_pp)
    if rc ~= 0 then
        local err = errmsg_pp[0] ~= nil and ffi.string(errmsg_pp[0]) or "Desconocido"
        error(string.format("[SQLite Error] Falló la ejecución SQL '%s': %s", sql, err))
    end
end

function SQLite:query(sql)
    local stmt_pp = ffi.new("sqlite3_stmt*[1]")
    local rc = libsqlite.sqlite3_prepare_v2(self.db, sql, -1, stmt_pp, nil)
    if rc ~= 0 then
        local err = ffi.string(libsqlite.sqlite3_errmsg(self.db))
        error(string.format("[SQLite Error] Falló la consulta '%s': %s", sql, err))
    end
    
    local stmt = stmt_pp[0]
    local rows = {}
    local ncols = libsqlite.sqlite3_column_count(stmt)
    local colnames = {}
    for i = 0, ncols - 1 do
        colnames[i + 1] = ffi.string(libsqlite.sqlite3_column_name(stmt, i))
    end
    
    while libsqlite.sqlite3_step(stmt) == 100 do -- SQLITE_ROW
        local row = {}
        for i = 0, ncols - 1 do
            local col_type = libsqlite.sqlite3_column_type(stmt, i)
            local col_name = colnames[i + 1]
            if col_type == 1 then
                row[col_name] = tonumber(libsqlite.sqlite3_column_int64(stmt, i))
            elseif col_type == 2 then
                row[col_name] = libsqlite.sqlite3_column_double(stmt, i)
            elseif col_type == 3 then
                local text = libsqlite.sqlite3_column_text(stmt, i)
                row[col_name] = text ~= nil and ffi.string(text) or nil
            elseif col_type == 4 then
                local blob_ptr = libsqlite.sqlite3_column_blob(stmt, i)
                local blob_bytes = libsqlite.sqlite3_column_bytes(stmt, i)
                if blob_ptr ~= nil and blob_bytes > 0 then
                    local bytes = ffi.cast("const unsigned char*", blob_ptr)
                    local hex_chars = {}
                    for b = 0, blob_bytes - 1 do
                        table.insert(hex_chars, string.format("%02X", bytes[b]))
                    end
                    row[col_name] = table.concat(hex_chars)
                else
                    row[col_name] = ""
                end
            else
                row[col_name] = nil
            end
        end
        table.insert(rows, row)
    end
    
    libsqlite.sqlite3_finalize(stmt)
    return rows
end

function SQLite:get_table_info(tname)
    local info = { columns = {}, pkeys = {} }
    local rows = self:query(string.format("PRAGMA table_info([%s]);", tname))
    for _, col in ipairs(rows) do
        info.columns[col.name] = {
            type = col.type:upper(),
            notnull = col.notnull == 1,
            dflt_value = col.dflt_value,
            pk = col.pk > 0
        }
        if col.pk > 0 then
            table.insert(info.pkeys, col.name)
        end
    end
    return info
end

return SQLite
