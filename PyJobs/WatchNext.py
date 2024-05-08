###### TEDx-Load-Aggregate-Model
######

import sys
import json
import pyspark
from pyspark.sql.functions import col, collect_list, array_join

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import collect_list, col, explode, arrays_zip



##### FROM FILES
tedx_dataset_path = "s3://tedx-bellosi-2024-data/final_list.csv"

###### READ PARAMETERS
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

##### START JOB CONTEXT AND JOB
sc = SparkContext()


glueContext = GlueContext(sc)
spark = glueContext.spark_session


    
job = Job(glueContext)
job.init(args['JOB_NAME'], args)


#### READ INPUT FILES TO CREATE AN INPUT DATASET
tedx_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(tedx_dataset_path)
    
tedx_dataset.printSchema()


#### FILTER ITEMS WITH NULL POSTING KEY
count_items = tedx_dataset.count()
count_items_null = tedx_dataset.filter("id is not null").count()

print(f"Number of items from RAW DATA {count_items}")
print(f"Number of items from RAW DATA with NOT NULL KEY {count_items_null}")

## READ THE DETAILS
details_dataset_path = "s3://tedx-bellosi-2024-data/details.csv"
details_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(details_dataset_path)

details_dataset = details_dataset.select(col("id").alias("id_ref"),
                                         col("description"),
                                         col("duration"),
                                         col("publishedAt"))
## READ THE IMAGES (VERSIONE NUOVA)
images_dataset_path = "s3://tedx-bellosi-2024-data/images.csv"
images_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(images_dataset_path)
 
images_dataset = images_dataset.select(col("id").alias("id_ref"),
                                         col("url"))
 
# AND JOIN WITH THE MAIN TABLE ( senza id_ref)
tedx_dataset_main = tedx_dataset.join(details_dataset, tedx_dataset.id == details_dataset.id_ref, "left") \
    .drop("id_ref")
    
#VERSIONE NUOVA DEL JOIN CON IL COLLEGAMENTO ALLE IMMAGINI
tedx_dataset_main = tedx_dataset_main.join(images_dataset, tedx_dataset_main.id == images_dataset.id_ref, "left") \
    .drop("id_ref")
    
    

#VERSIONE PER LA SECONDA PARTE DEL PROGETTO, DANDO I CONSIGLIATI

## READ THE RELATED VIDEOS (VERSIONE NUOVA)
related_videos_path = "s3://tedx-bellosi-2024-data/related_videos.csv"
related_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(related_videos_path)
 
related_dataset = related_dataset.groupBy(col("id").alias("id_from")).agg(collect_list("related_id").alias("id_related_list"),collect_list("title").alias("title_related_list"))
#,col("title").alias("title_related")                                  
#VERSIONE NUOVA DEL JOIN CON IL COLLEGAMENTO AI RELATIVI VIDEO
tedx_dataset_main = tedx_dataset_main.join(related_dataset, tedx_dataset_main.id == related_dataset.id_from, "left") \
    .drop("id_from") \
    .select(col("id").alias("id_related"), col("*")) 
#    .drop("id") 
#tedx_dataset_main = tedx_dataset_main.withColumn("related_video_title", explode(arrays_zip("id_related_list", "title_related_list"))) \
#    .select("id_related", "title", "related_video_title.*")
related_dataset.printSchema()


#CHATGTP
#related_dataset = related_dataset.groupBy(col("id").alias("id_related")) \
#    .agg(collect_list("related_id").alias("id_related_list"), collect_list("title").alias("title_related_list"))

# Join the main dataset with related videos dataset
#tedx_dataset_main = tedx_dataset_main.join(related_dataset, tedx_dataset_main.id == related_dataset.id_related, "left_outer") \
#    .select(tedx_dataset_main["*"], related_dataset["id_related_list"], related_dataset["title_related_list"])

# Explode the arrays to print related videos and titles together
#tedx_dataset_main = tedx_dataset_main.withColumn("related_video_title", explode(arrays_zip("id_related_list", "title_related_list"))) \
#    .select("id", "title", "related_video_title.*")
#FINE CHATGTP    
#FINE PARTE AGGIUNTA
tedx_dataset_main.printSchema()

## READ TAGS DATASET
tags_dataset_path = "s3://tedx-bellosi-2024-data/tags.csv"
tags_dataset = spark.read.option("header","true").csv(tags_dataset_path)


# CREATE THE AGGREGATE MODEL, ADD TAGS TO TEDX_DATASET ( Prendo tutti i tag specificati)
tags_dataset_agg = tags_dataset.groupBy(col("id").alias("id_ref")).agg(collect_list("tag").alias("tags"))
tags_dataset_agg.printSchema()
tedx_dataset_agg = tedx_dataset_main.join(tags_dataset_agg, tedx_dataset.id == tags_dataset_agg.id_ref, "left") \
    .drop("id_ref") \
    .select(col("id").alias("_id"), col("*")) \
    .drop("id") \

tedx_dataset_agg.printSchema()


write_mongo_options = {
    "connectionName": "Progetto2",
    "database": "unibg_tedx_2024",
    "collection": "tedx_data",
    "ssl": "true",
    "ssl.domain_match": "false"}
from awsglue.dynamicframe import DynamicFrame
tedx_dataset_dynamic_frame = DynamicFrame.fromDF(tedx_dataset_agg, glueContext, "nested")

glueContext.write_dynamic_frame.from_options(tedx_dataset_dynamic_frame, connection_type="mongodb", connection_options=write_mongo_options)

