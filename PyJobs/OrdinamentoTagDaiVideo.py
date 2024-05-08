###### TEDx-Load-Aggregate-Model
######

import sys
import json
import pyspark
import pandas as pd
from pyspark.sql.functions import col, collect_list, array_join

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, count, struct


###### READ PARAMETERS
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

##### START JOB CONTEXT AND JOB
sc = SparkContext()


glueContext = GlueContext(sc)
spark = glueContext.spark_session


    
job = Job(glueContext)
job.init(args['JOB_NAME'], args)




#### FILTER ITEMS WITH NULL POSTING KEY



# Leggi il dataset dei tag
tags_dataset_path = "s3://tedx-bellosi-2024-data/tags.csv"
tags_dataset = spark.read.option("header", "true").csv(tags_dataset_path)

# Leggi il dataset principale dei video
tedx_dataset_path = "s3://tedx-bellosi-2024-data/final_list.csv"
tedx_dataset = spark.read.option("header", "true").csv(tedx_dataset_path)

# Esegui una join tra i tag e i video per ottenere gli ID e i titoli dei video per ciascun tag
tag_video_info = tags_dataset.join(tedx_dataset, tags_dataset.id == tedx_dataset.id, "left") \
    .select(tags_dataset["tag"], tedx_dataset["id"].alias("video_id"), tedx_dataset["title"].alias("video_title"))

# Raggruppa per tag e crea una struttura dati all'interno di ciascun tag
tag_info = tag_video_info.groupBy("tag") \
    .agg(count("*").alias("tag_count"), collect_list(struct(col("video_id"), col("video_title"))).alias("videos"))

# Mostra i risultati
tag_info = tag_info.orderBy(col("tag_count").desc())

#PARTE AGGIUNTA PER ORDINARE
# Converti il DataFrame Spark in un DataFrame pandas per ulteriore ordinamento
#tag_counts_df = tag_info.toPandas()

# Ordina il DataFrame pandas per frequenza decrescente
#tag_counts_df = tag_counts_df.sort_values(by="tag_count", ascending=False)

# Converte il DataFrame pandas in un DataFrame Spark
#tag_counts_sorted = spark.createDataFrame(tag_counts_df)

# Mostra i risultati
#tag_counts_sorted.show()


#FINE PARTE AGGIUNTA PER ORDINARE
tag_info.show(truncate=False)
#---------------
# Converte il DataFrame Spark in un DynamicFrame
tag_counts_dynamic_frame = DynamicFrame.fromDF(tag_info, glueContext, "tag_counts_dynamic_frame")

# Opzioni per la scrittura nel database MongoDB
write_mongo_options = {
    "connectionName": "Progetto2",
    "database": "unibg_tedx_2024",
    "collection": "tag_countsFromVideo",
    "ssl": "true",
    "ssl.domain_match": "false"
}

# Scrivi il DynamicFrame nel database MongoDB
glueContext.write_dynamic_frame.from_options(
    tag_counts_dynamic_frame,
    connection_type="mongodb",
    connection_options=write_mongo_options
)
#---------------


#write_mongo_options = {
#    "connectionName": "Progetto2",
#    "database": "unibg_tedx_2024",
#    "collection": "tag_counts",
#    "ssl": "true",
#    "ssl.domain_match": "false"}

#tedx_dataset_dynamic_frame = DynamicFrame.fromDF(tedx_dataset_agg, glueContext, "nested")

#glueContext.write_dynamic_frame.from_options(tedx_dataset_dynamic_frame, connection_type="mongodb", connection_options=write_mongo_options)

