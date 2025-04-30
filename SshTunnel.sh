# Comando para crear tunnel ssh del cual nos podemos conectar desde otro pc remotamente y cifrar la conexión haciendola mas segura.
ssh -L xxxx:localhost(IP):xxxx UsuarioRemoto@ServidorRemoto 
# Los puertos inferiores a 1024 solo se pueden usar si eres superusuario
