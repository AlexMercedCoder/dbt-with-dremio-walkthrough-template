# Using dbt with Dremio Walkthrough

Unified Analytics with Dremio unlocks the ability to streamline your data workflows by providing a single, cohesive platform for querying and analyzing data across multiple sources. By integrating dbt into your Dremio semantic layer, you can elevate your data modeling process to new heights. Dremio's dbt integration not only orchestrates SQL workflows but also enables seamless synchronization of documentation and tags directly with Dremio, ensuring that your data assets are well-organized and discoverable. With the ability to run tests, model across various Dremio-supported data sources, and define incremental pipelines, you can build robust and scalable analytics processes. Moreover, this integration allows you to define and optimize reflections directly in your dbt models, accelerating query performance while maintaining consistency and governance across your datasets. This combination of Dremio and dbt creates a powerful toolkit for curating a unified, efficient, and high-performance analytics environment.

## Starting Up Dremio on Your Laptop

If you just need Dremio running on your laptop for this walkthrough run the docker command below:

```
docker run -p 9047:9047 -p 31010:31010 -p 45678:45678 -p 32010:32010 -e DREMIO_JAVA_SERVER_EXTRA_OPTS=-Dpaths.dist=file:///opt/dremio/data/dist --name try-dremio dremio/dremio-oss
```

If you want to run Dremio along with other data infrastructure for more complex locally run data lakehouse environments, check out [this repository of docker-compose files](https://github.com/developer-advocacy-dremio/dremio-compose).

Once Dremio is running in docker head over to localhost:9047 in your browser and create your username and password and take note of them. Then add the "Sample Source" which gives you access to data sets you can experiment with. Also create an initial space, spaces are top level storage for folders and views.

## Creating a Python Virtual Environment and Installing dbt

You should always isolate your python dependencies by creating a virtual environment for each project.

Command to create the environment:

```
python -m venv venv
```

This will create a `venv` folder with your virtual environment we want to run the activate script in that folder:

- Linux/Mac `source venv/bin/activate`
- Windows (CMD) `venv\Scripts\activate`
- Windows (powershell) `.\venv\Scripts\Activate.ps1`

This script will update the `pip` and `python` command in your active shell to use the virtual environment not your global python environment.

Now we can install `dbt-dremio` and other libraries you'd want to use.

`pip install dbt-dremio`

## Creating Your dbt Project

Now we can create a new dbt project using the command `dbt init`, this will be begin a series of questions to setup the global configurations of your project, these configurations are stored in `~/.dbt/profiles.yml`. You can setup more localized configurations in your project as we'll discuss shortly.

### `dbt init` prompts

#### Basics
1. *name of your project*: enter whatever name you like
2. *number of type of project*: enter the number for `dremio` (may not be 1 if you have other dbt libraries installed)
3. *type of dremio project*: For this exercise choose `2` (The Following questions will defer depending on what you select for this option)
    - [1] dremio_cloud (if you are using Dremio Cloud, you'll need a Personal Access Token generated from the UI or REST API)
    - [2] software_with_username_password (if you are self-deploying Dremio like using Docker and want to authenticate using Username/Password)
    - [3] software_with_pat (if you are self-deploying Dremio like using Docker and want to authenticate using Personal Access Token which must be generated with Dremio REST API)

#### Connection Settings and Authentication
4. *software host*: The host part of the url for your Dremio instance, if running on your laptop this would be `localhost` or `127.0.0.1`
5. *port*: The port Dremio is running on within the host, which should typically be port `9047`
6. *username*: Your Dremio Username
7. *password*: Your Dremio Password
8. *use_ssl*: Whether to use a SSL connection (choose False if working locally)

#### 9-12: Default View and Table Storage Location

###### Materializing Tables Location

- `object_storage_source`: must be a Dremio source where data can be written (S3, GCP, HDFS, AWS Glue, Polaris, Nessie), if you don't have one of these sources connected to Dremio accept the default `$scratch` option.
- `object_storage_path`: the sub path for your object_storage_source

These two settings establish where physical tables are created by default, so if I want to create tables by default in `nessie.marketing.bronze` then the values would be:

- `object_storage_source`: `nessie`
- `object_storage_path`: `marketing.bronze`

###### Creating Views Location

- `dremio_space`: This can be any Dremio Source that can storage views (Spaces, Arctic Catalog, Nessie, Dremio Catalog) if you don't have any of these select the default option which will use the users homespace (every user gets a "home" space named after their username on Dremio Self-Deployed)

- `dremio_space_folder`: This the sub path for the dremio_space

If I want views to be create by a default in `default.views` then the values would be

- `dremio_space`: `default`
- `dremio_space_folder`: `views`

#### 13 Thread

Just select the default 1 thread unless you want to use more threads.

## Customizing Configurations in dbt with Dremio

When working with dbt and Dremio, you can override the default configurations for materialized tables and views at both the project level using the `dbt_project.yml` file and the model level using the `config` function within your model file. This flexibility allows you to tailor the storage locations for your tables and views based on your specific needs.

#### Configuring Defaults for a Group of Models in `dbt_project.yml`

To configure a group of models, update the `dbt_project.yml` file under the `models` section. For example, if you want to store certain tables by default in `nessie.marketing.bronze` and certain views in `default.views`, you can specify the following configuration:

```yaml
models:
  my_project:
    +object_storage_source: nessie
    +object_storage_path: marketing.bronze
    +dremio_space: default
    +dremio_space_folder: views
```
This configuration ensures that all models under the `models/my_project` folder will store materialized tables in the `nessie.marketing.bronze` path and create views in the `default.views` folder unless overridden at the individual model level.

#### Configuring an Individual Model with the config Function
To set custom configurations for a specific model, you can use the config function directly within the model file. For example, if you want to store the output of a specific model in the nessie.sales.silver path for tables and in the default.custom_views folder for views, you can include the following in your model SQL file:

```sql
{{ config(
    object_storage_source='nessie',
    object_storage_path='sales.silver',
    dremio_space='default',
    dremio_space_folder='custom_views'
) }}


SELECT *
FROM source_table
```

#### Explanation of Key Configuration Options

- `object_storage_source:` Defines the Dremio source where physical tables are created (e.g., nessie, S3, Polaris). If none of these are available, the default $scratch option is used.
- `object_storage_path:` Specifies the subpath within the object_storage_source for materialized tables.
- `dremio_space:` Sets the Dremio source for views (e.g., Spaces, Arctic Catalog, Nessie).
- `dremio_space_folder:` Defines the folder within the dremio_space for creating views.

By customizing these configurations, you can effectively organize your tables and views in Dremio to align with your data modeling and organizational standards.

## Common dbt Commands and Their Purpose

To effectively use dbt with Dremio, it’s important to familiarize yourself with the key dbt commands. **Before running any dbt command, ensure that your terminal is navigated to the folder containing your `dbt_project.yml` file.** This ensures dbt has access to the project configuration and can execute the commands successfully.

#### **Core dbt Commands**

1. **`dbt run`**
   - **Purpose**: Executes all the models defined in your project by running the SQL files and materializing the results (tables, views, or incremental models) according to the configurations.
   - **Use Case**: Use this command to build or refresh your data models in the target database.

   ```bash
   dbt run
   ```

2. dbt build

Purpose: Combines multiple actions—compiling, running, testing, and building documentation—all in one command.
Use Case: Use this for an end-to-end execution of models, ensuring they run, pass tests, and have documentation updated.
bash
Copy
Edit
dbt build
dbt test

Purpose: Runs the tests defined in your tests directory or within your models to validate data quality and integrity.
Use Case: Use this command to check that your data meets the defined constraints (e.g., unique values, no nulls).
bash
Copy
Edit
dbt test
dbt compile

Purpose: Compiles all the SQL files in your project into executable SQL queries but does not execute them.
Use Case: Use this command to validate the SQL generated by dbt without actually running it.
bash
Copy
Edit
dbt compile
dbt docs generate

Purpose: Generates HTML-based documentation for your project, including model relationships, dependencies, and metadata.
Use Case: Use this to create a navigable interface for understanding your data models.
bash
Copy
Edit
dbt docs generate
dbt docs serve

Purpose: Serves the documentation generated by dbt docs generate on a local web server.
Use Case: Use this to view and interact with your project documentation in a browser.
bash
Copy
Edit
dbt docs serve
dbt debug

Purpose: Verifies that your dbt setup and configurations are correct and that dbt can connect to the target database.
Use Case: Use this command to troubleshoot connection or configuration issues.
bash
Copy
Edit
dbt debug
dbt clean

Purpose: Removes any artifacts created by dbt, such as compiled files or cached files in the target/ directory.
Use Case: Use this command to reset the environment if you encounter unexpected behavior.
bash
Copy
Edit
dbt clean
dbt seed

Purpose: Loads CSV files from the data/ directory into your database as tables.
Use Case: Use this command to prepare static or reference data for your project.
bash
Copy
Edit
dbt seed
dbt snapshot

Purpose: Executes snapshot models to capture the state of your data at specific points in time.
Use Case: Use this to maintain historical data changes over time.
bash
Copy
Edit
dbt snapshot
dbt list

Purpose: Lists the resources (models, tests, seeds, etc.) in your project.
Use Case: Use this to get a quick overview of the components in your dbt project.
bash
Copy
Edit
dbt list
Tips for Using dbt Commands
Commands like dbt run, dbt test, and dbt build can be scoped to specific models or directories by using selectors (e.g., dbt run --select model_name).
Use dbt clean and dbt debug to ensure a smooth experience when switching between environments or debugging issues.
Regularly generate and serve documentation with dbt docs to maintain an up-to-date understanding of your project.
By mastering these commands, you’ll be equipped to manage, test, and document your dbt project efficiently!