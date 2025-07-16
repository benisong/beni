module.exports = {
  apps : [
    {
      name   : "sillytavern-backend",
      cwd    : "./backend",
      script : "app.js",
      watch  : false,
      env: { "PORT": 3001 }
    },
    {
      name   : "sillytavern-frontend",
      cwd    : "./frontend",
      script : "node_modules/.bin/serve",
      args   : "-s build -l 3000",
      watch  : false
    }
  ]
}
