import sys
import json
import pyspark
from pyspark.sql.functions import col, count, collect_list, struct
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

# READ PARAMETERS
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

# START JOB CONTEXT AND JOB
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
#--
# Leggi il dataset degli URL dei video
videos_url_dataset_path = "s3://tedx-bellosi-2024-data/lista_video_primo_only_links.csv"
videos_url_dataset = spark.read.option("header", "true").csv(videos_url_dataset_path)

# Leggi il dataset principale dei video
tedx_dataset_path = "s3://tedx-bellosi-2024-data/final_list.csv"
tedx_dataset = spark.read.option("header", "true").csv(tedx_dataset_path)

# Esegui il join tra gli URL dei video e "final_list" per ottenere l'ID di ogni video
videos_with_id = videos_url_dataset.join(tedx_dataset, videos_url_dataset.url == tedx_dataset.url, "left") \
    .select(tedx_dataset["id"].alias("video_id"))

#---
# READ TAGS DATASET
tags_dataset_path = "s3://tedx-bellosi-2024-data/tags.csv"
tags_dataset = spark.read.option("header", "true").csv(tags_dataset_path)

# JOIN TAGS AND VIDEO DATASETS
tag_video_info = tags_dataset.join(videos_with_id, tags_dataset.id == videos_with_id.id, "left") \
    .select(tags_dataset["tag"], videos_with_id["id"].alias("video_id"), videos_with_id["title"].alias("video_title"))

# GROUP BY TAGS AND CREATE STRUCTURE
tag_info = tag_video_info.groupBy("tag") \
    .agg(count("*").alias("tag_count"), collect_list(struct(col("video_id"), col("video_title"))).alias("videos"))

# GROUP ALL TAGS INFO INTO A SINGLE DOCUMENT
all_tags_info = tag_info.groupBy().agg(collect_list(struct(col("tag"), col("tag_count"), col("videos"))).alias("all_tags_info"))

# SHOW RESULTS
all_tags_info.show(truncate=False)

# WRITE TO MONGODB
all_tags_dynamic_frame = DynamicFrame.fromDF(all_tags_info, glueContext, "all_tags_dynamic_frame")

write_mongo_options = {
    "connectionName": "Progetto2",
    "database": "unibg_tedx_2024",
    "collection": "tag_from_link_ofe",
    "ssl": "true",
    "ssl.domain_match": "false"
}

glueContext.write_dynamic_frame.from_options(
    all_tags_dynamic_frame,
    connection_type="mongodb",
    connection_options=write_mongo_options
)
