**What is PgP Generator?**

PgP Generator (or Pg Square) is a utility written in PgSQL that generates stored procedures around tables. The stored procedures perform the following basic operations:

  * Insert into a given table
  * Update a given table knowing the primary key
  * Retrieving data: all records and by the table's primary key

**Why use PgP Generator?**

  * Written in PgSQL it will run anywhere [PostgreSQL](http://postgresql.org) runs (Linux; Solaris and Windows)
  * Eliminates time spent writting basic CRUD operations
  * Increase productivity and focus on implementing business logic & security for the database
  * Compared to other products this script is light-weight and free
  * Available online Generator allows customized a script file appropriate for your system (setting owner, target schema, updates comments for your system).

The current version is optimized and has been tested with PostgreSQL 7.x and 8.3 and is working well.

**Where is the source code ?**

The project is hosted here on [google](http://code.google.com/p/pgp-generator/downloads/list) PgP-Generator is developed under [GPL v3](http://www.gnu.org/licenses/gpl.html) and comes with NO WARRANTY or implied warranty. Feel free to change; and distribute at will (giving proper credit).

**Coming Soon**
  * Retrieve operations with foreign key support
  * Code optimization
  * Adding a package for logging

`Enjoy.