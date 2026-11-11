-- socket.lua: Wrapper nativo de sockets POSIX con LuaJIT FFI
local ffi = require("ffi")

ffi.cdef[[
    typedef unsigned short sa_family_t;
    typedef uint32_t in_addr_t;
    typedef uint16_t in_port_t;
    typedef uint32_t socklen_t;
    typedef long ssize_t;

    struct in_addr {
        in_addr_t s_addr;
    };

    struct sockaddr {
        sa_family_t sa_family;
        char        sa_data[14];
    };

    struct sockaddr_in {
        sa_family_t    sin_family;
        in_port_t      sin_port;
        struct in_addr sin_addr;
        char           sin_zero[8];
    };

    int socket(int domain, int type, int protocol);
    int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
    int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    int listen(int sockfd, int backlog);
    int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
    int close(int fd);
    ssize_t send(int sockfd, const void *buf, size_t len, int flags);
    ssize_t recv(int sockfd, void *buf, size_t len, int flags);

    unsigned short htons(unsigned short hostshort);
    unsigned long inet_addr(const char *cp);
]]

local Socket = {}
Socket.__index = Socket

function Socket.tcp_server(port, backlog)
    backlog = backlog or 5
    local server_fd = ffi.C.socket(2, 1, 0) -- AF_INET = 2, SOCK_STREAM = 1
    if server_fd < 0 then
        error("[Socket Error] No se pudo crear el socket.")
    end

    -- Permitir reutilización del puerto inmediatamente (Evita el error "Address already in use")
    local optval = ffi.new("int[1]", 1)
    ffi.C.setsockopt(server_fd, 1, 2, optval, ffi.sizeof(optval)) -- SOL_SOCKET = 1, SO_REUSEADDR = 2 (en Linux)

    local addr = ffi.new("struct sockaddr_in")
    addr.sin_family = 2 -- AF_INET
    addr.sin_port = ffi.C.htons(port)
    addr.sin_addr.s_addr = ffi.C.inet_addr("0.0.0.0")

    local rc = ffi.C.bind(server_fd, ffi.cast("const struct sockaddr*", addr), ffi.sizeof(addr))
    if rc < 0 then
        ffi.C.close(server_fd)
        error(string.format("[Socket Error] Falló el bind en el puerto %d (Puerto ocupado).", port))
    end

    rc = ffi.C.listen(server_fd, backlog)
    if rc < 0 then
        ffi.C.close(server_fd)
        error("[Socket Error] Falló el listen.")
    end

    return setmetatable({ fd = server_fd }, Socket)
end

function Socket:accept()
    local client_addr = ffi.new("struct sockaddr_in")
    local addr_len = ffi.new("socklen_t[1]", ffi.sizeof(client_addr))
    
    local client_fd = ffi.C.accept(self.fd, ffi.cast("struct sockaddr*", client_addr), addr_len)
    if client_fd < 0 then
        return nil, "Error al aceptar conexión"
    end
    
    return client_fd
end

function Socket.send(client_fd, data)
    return ffi.C.send(client_fd, data, #data, 0)
end

function Socket.recv(client_fd, max_len)
    max_len = max_len or 1024
    local buf = ffi.new("char[?]", max_len)
    local received = ffi.C.recv(client_fd, buf, max_len - 1, 0)
    if received > 0 then
        return ffi.string(buf, received)
    end
    return nil
end

function Socket.close(fd)
    ffi.C.close(fd)
end

return Socket
