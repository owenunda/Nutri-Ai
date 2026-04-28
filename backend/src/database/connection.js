import { config } from "../config/env_config.js"
import { Pool } from "pg"
import { AppError } from "../utils/AppError.js"

const pool = new Pool({
  user: config.db.user,
  host: config.db.host,
  database: config.db.name,
  password: config.db.password,
  port: config.db.port,
})

export default pool