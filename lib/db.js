import mysql from 'mysql2/promise';
export default mysql.createPool(process.env.MYSQL_URL);
