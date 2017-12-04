#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Nov 26 16:49:58 2017

@author: kartiw
"""

from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession, functions, types, SQLContext, Row
from pyspark.sql.functions import *
import sys
from optparse import OptionParser
import itertools

#connection obj
conf = SparkConf().setAppName('BDProject')
sc = SparkContext.getOrCreate(conf=conf)
spark = SparkSession.builder.appName('BDProject').getOrCreate()
sqlContext = SQLContext(sc)

#reading data
data = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/Extracted/", header=True,  sep='\t')
data.cache()
data.createOrReplaceTempView('data')
###################################################################################
#Getting month
from datetime import datetime
def get_month(date):
    return datetime.strptime(date[4:6],"%m").strftime("%b")
    
my_month = functions.udf(get_month, types.StringType())
    
data= data.withColumn('MONTH', my_month(data['INCIDDTE']))    
data.createOrReplaceTempView('data')
    

######################################################################################
#getting location code details
loc = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/MetaData/location.csv", header=True)
loc.createOrReplaceTempView('loc')
#getting offender code details
offender = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/MetaData/offenders.csv", header=True)
offender.createOrReplaceTempView('offender')
#getting victim code details
victims = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/MetaData/bias_victims.csv", header=True)
victims.createOrReplaceTempView('victims')
#getting offence code details
offencecode = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/MetaData/offencecode.csv", header=True)
offencecode.createOrReplaceTempView('offencecode')

#joining all the above dataframes to get the code details
data=spark.sql("""SELECT *, trim(loc.LOCCOD1EXT) AS LOCCOD1EXTNEW FROM data
               LEFT JOIN loc USING(LOCCOD1)""")
data.createOrReplaceTempView('data')

data=spark.sql("""SELECT *, trim(offender.GOFFRACEXT) AS GOFFRACEXTNEW FROM data
               LEFT JOIN offender USING(GOFFRAC)""")
data.createOrReplaceTempView('data')

data=spark.sql("""SELECT *, trim(victims.BIASMO1EXT) AS BIASMO1EXTNEW FROM data
               LEFT JOIN victims USING(BIASMO1)""")
data.createOrReplaceTempView('data')

data=spark.sql("""SELECT *, trim(offencecode.OFFCOD1EXT) AS OFFCOD1EXTNEW FROM data
               LEFT JOIN offencecode USING(OFFCOD1)""")
data.createOrReplaceTempView('data')
#####################################################################################
#####################################################################################

#Avg crime per 1000 for 2015
location = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/locationdata/")
location.createOrReplaceTempView('location')

geocodes=spark.sql("""SELECT SPLIT(_c0,',')[0] AS GCITY, TRIM(SPLIT(_c0,',')[1]) AS GSTATECOD, _c1 AS LAT,_c2 AS LON from location""")
geocodes.createOrReplaceTempView('geocodes')

datawithgeo=spark.sql("""SELECT data.*,geocodes.LAT,geocodes.LON FROM data
               LEFT JOIN geocodes
               ON data.CITY = geocodes.GCITY AND data.STATECOD = geocodes.GSTATECOD
               WHERE MASTERYR=2015""") 
datawithgeo.createOrReplaceTempView('datawithgeo')

avg=spark.sql("""SELECT CITY, STATECOD,OFFCOD1EXTNEW,(COUNT(OFFCOD1)/POP1)*1000 AS CRIME_PER_THOUSAND FROM datawithgeo 
            GROUP BY CITY,STATECOD,OFFCOD1EXTNEW,POP1
            ORDER BY CRIME_PER_THOUSAND DESC""")

avg.createOrReplaceTempView('avg')
avgnew=spark.sql("""SELECT avg.*, datawithgeo.LAT, datawithgeo.LON  
              FROM avg
              JOIN datawithgeo ON avg.city == datawithgeo.city AND avg.statecod = datawithgeo.statecod""")
avgnew.createOrReplaceTempView('avgnew')

avgnew=spark.sql("SELECT DISTINCT * FROM avgnew")
avgnew.createOrReplaceTempView('avgnew')

avgnew=spark.sql("SELECT * FROM avgnew where CRIME_PER_THOUSAND IS NOT NULL AND LAT IS NOT NULL AND LON IS NOT NULL")
avgnew.createOrReplaceTempView('avgnew')

######################################################################################
#Avg crime per 1000
location = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/locationdata/")
location.createOrReplaceTempView('location')

geocodes=spark.sql("""SELECT SPLIT(_c0,',')[0] AS GCITY, TRIM(SPLIT(_c0,',')[1]) AS GSTATECOD, _c1 AS LAT,_c2 AS LON from location""")
geocodes.createOrReplaceTempView('geocodes')

datawithgeo=spark.sql("""SELECT data.*,geocodes.LAT,geocodes.LON FROM data
               LEFT JOIN geocodes
               ON data.CITY = geocodes.GCITY AND data.STATECOD = geocodes.GSTATECOD""") 
datawithgeo.createOrReplaceTempView('datawithgeo')

avg=spark.sql("""SELECT CITY, STATECOD,OFFCOD1EXTNEW,(COUNT(OFFCOD1)/POP1)*1000 AS CRIME_PER_THOUSAND FROM datawithgeo 
            GROUP BY CITY,STATECOD,OFFCOD1EXTNEW,POP1,MASTERYR
            ORDER BY CRIME_PER_THOUSAND DESC""")

avg.createOrReplaceTempView('avg')
avgnew=spark.sql("""SELECT avg.*, datawithgeo.LAT, datawithgeo.LON, datawithgeo.MASTERYR  
              FROM avg
              JOIN datawithgeo ON avg.city == datawithgeo.city AND avg.statecod = datawithgeo.statecod""")
avgnew.createOrReplaceTempView('avgnew')

avgnew=spark.sql("SELECT DISTINCT * FROM avgnew")
avgnew.createOrReplaceTempView('avgnew')

avgnew=spark.sql("SELECT * FROM avgnew where CRIME_PER_THOUSAND IS NOT NULL AND LAT IS NOT NULL AND LON IS NOT NULL")
avgnew.createOrReplaceTempView('avgnew')

#####################################################################################
#count of crime for 2015
location = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/locationdata/")
location.createOrReplaceTempView('location')

geocodes=spark.sql("""SELECT SPLIT(_c0,',')[0] AS GCITY, TRIM(SPLIT(_c0,',')[1]) AS GSTATECOD, _c1 AS LAT,_c2 AS LON from location""")
geocodes.createOrReplaceTempView('geocodes')

datawithgeo=spark.sql("""SELECT data.*,geocodes.LAT,geocodes.LON FROM data
               LEFT JOIN geocodes
               ON data.CITY = geocodes.GCITY AND data.STATECOD = geocodes.GSTATECOD
               WHERE MASTERYR=2015""") 
datawithgeo.createOrReplaceTempView('datawithgeo')

avg=spark.sql("""SELECT CITY, STATECOD,OFFCOD1EXTNEW,COUNT(OFFCOD1) AS COUNT_OF_CRIME FROM datawithgeo 
            GROUP BY CITY,STATECOD,OFFCOD1EXTNEW
            ORDER BY COUNT_OF_CRIME DESC""")

avg.createOrReplaceTempView('avg')
avgnew=spark.sql("""SELECT avg.*, datawithgeo.LAT, datawithgeo.LON  
              FROM avg
              JOIN datawithgeo ON avg.city == datawithgeo.city AND avg.statecod = datawithgeo.statecod""")
avgnew.createOrReplaceTempView('avgnew')

avgnew=spark.sql("SELECT DISTINCT * FROM avgnew")
avgnew.createOrReplaceTempView('avgnew')

avgnew=spark.sql("SELECT * FROM avgnew where COUNT_OF_CRIME IS NOT NULL AND LAT IS NOT NULL AND LON IS NOT NULL")
avgnew.createOrReplaceTempView('avgnew')
################################################################################################

#count of crime for ALL yr
location = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/locationdata/")
location.createOrReplaceTempView('location')

geocodes=spark.sql("""SELECT SPLIT(_c0,',')[0] AS GCITY, TRIM(SPLIT(_c0,',')[1]) AS GSTATECOD, _c1 AS LAT,_c2 AS LON from location""")
geocodes.createOrReplaceTempView('geocodes')

datawithgeo=spark.sql("""SELECT data.*,geocodes.LAT,geocodes.LON FROM data
               LEFT JOIN geocodes
               ON data.CITY = geocodes.GCITY AND data.STATECOD = geocodes.GSTATECOD""") 
datawithgeo.createOrReplaceTempView('datawithgeo')

avg=spark.sql("""SELECT CITY, STATECOD,OFFCOD1EXTNEW,COUNT(OFFCOD1) AS COUNT_OF_CRIME FROM datawithgeo 
            GROUP BY CITY,STATECOD,OFFCOD1EXTNEW
            ORDER BY COUNT_OF_CRIME DESC""")

avg.createOrReplaceTempView('avg')
avgnew=spark.sql("""SELECT avg.*, datawithgeo.LAT, datawithgeo.LON, datawithgeo.MASTERYR  
              FROM avg
              JOIN datawithgeo ON avg.city == datawithgeo.city AND avg.statecod = datawithgeo.statecod""")
avgnew.createOrReplaceTempView('avgnew')

avgnew=spark.sql("SELECT DISTINCT * FROM avgnew")
avgnew.createOrReplaceTempView('avgnew')

avgnew=spark.sql("SELECT * FROM avgnew where COUNT_OF_CRIME IS NOT NULL AND LAT IS NOT NULL AND LON IS NOT NULL")
avgnew.createOrReplaceTempView('avgnew')

################################################################################################