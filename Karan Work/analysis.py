#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Nov 26 13:15:27 2017

@author: kartiw
"""
#import pandas as pd

#yr2011=pd.read_csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/2011.tsv", sep="\t")
#yr2012=pd.read_csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/2012.tsv", sep="\t")
#yr2013=pd.read_csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/2013.tsv", sep="\t")
#yr2014=pd.read_csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/2014.tsv", sep="\t")
#yr2015=pd.read_csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/2015.tsv", sep="\t")

#newdf= pd.concat([yr2011,yr2012,yr2013,yr2014,yr2015], axis=0)


#imports
from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession, functions, types, SQLContext, Row
from pyspark.sql.functions import *
import sys
from optparse import OptionParser

#connection obj
conf = SparkConf().setAppName('BDProject')
sc = SparkContext.getOrCreate(conf=conf)
spark = SparkSession.builder.appName('BDProject').getOrCreate()
sqlContext = SQLContext(sc)


#custom parser
parser = OptionParser()
parser.add_option("--col", "--column", dest="column", help="Sepcifies columns to display")
parser.add_option("--con", "--condition", dest="condition", help="Specifies columns where conditions will be apllied to")
parser.add_option("--grp", "--group", dest="group", help="Specifies Values of the condiions")
parser.add_option("--fn", "--filename", dest="filename", help="Specifies output filename")
(options, args) = parser.parse_args()

#taking all CLI and flags
displayCol = options.column
conditions = options.condition
grouping = options.group
fn=options.filename

#setting flag to understand which type of syntax to use
#sqlflag=1 - only selecting columns
#sqlFlag=2 - columns and condition
#sqlFlag=3 - columns and condition and grouping
#sqlFlag=4 - columns and grouping
sqlflag=None

if(displayCol==None):
    print("No columns were selected,exiting")
    sys.exit()

if(displayCol!=None and conditions!=None and grouping!=None):
    sqlflag=3
    
if(displayCol!=None and conditions==None and grouping!=None):
    sqlflag=4
    print("No conditions were set")
    
if(displayCol!=None and conditions!=None and grouping==None):
    sqlflag=2
    print("No grouping were set")

if(displayCol!=None and conditions==None and grouping==None):
    sqlflag=1
    print("No conditon or grouping were set")

#reading the crime data
data = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/Extracted/", header=True, sep='\t')
data.cache()
data.createOrReplaceTempView('data')

#Getting month
from datetime import datetime
def get_month(date):
    return datetime.strptime(date[4:6],"%m").strftime("%b")
    
my_month = functions.udf(get_month, types.StringType())
    
data= data.withColumn('MONTH', my_month(data['INCIDDTE']))    
data.createOrReplaceTempView('data')

#getting codes for location, offenders, offencecode, victims
loc = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/MetaData/location.csv", header=True)
loc.createOrReplaceTempView('loc')

offender = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/MetaData/offenders.csv", header=True)
offender.createOrReplaceTempView('offender')

victims = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/MetaData/bias_victims.csv", header=True)
victims.createOrReplaceTempView('victims')

offencecode = spark.read.csv("/home/kartiw/anaconda-workspace/python3-wokspace/Project/Big Data Project - Hate Crime/Data/MetaData/offencecode.csv", header=True)
offencecode.createOrReplaceTempView('offencecode')

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

#making the condition string
if(conditions!=None):
    condition=conditions.split(",")
    constring=""
    valfalg=False
    for con in condition:
        if con == 'AND' or con=='OR' or con=='NOT':
            constring=constring + " "
            constring=constring + con
            constring=constring + " "
    
        else:
            if(valfalg==False):
                constring=constring + con
                valfalg=True
    
            else:
                
                #if(con == "="):
                #    constring=constring + '='
                #if(con == ">"):
                #    constring=constring + '>'
                #if(con == "<"):
                #    constring=constring + '<'
                    
                if(con.isalpha()):
                    constring=constring + '"'
                    constring=constring + con
                    constring=constring + '"'
                else:
                    constring=constring + con
                
                valfalg=False
    
    #print(constring)

#executing appropriate query based on sqlflag
if(sqlflag==1):
    query='''SELECT {0} FROM data'''.format(displayCol);
    print(query)
    filteredDS=sqlContext.sql(query)
    filteredDS.show()
    
if(sqlflag==2):            
    query='''SELECT {0} FROM data WHERE {1}'''.format(displayCol,constring);
    print(query)
    filteredDS=sqlContext.sql(query)
    filteredDS.show()    

if(sqlflag==3):
    query='''SELECT {0} FROM data WHERE {1} GROUP BY {2}'''.format(displayCol,constring,grouping);
    print(query)
    filteredDS=sqlContext.sql(query)
    filteredDS.show()
    
if(sqlflag==4):
    query='''SELECT {0} FROM data GROUP BY {1}'''.format(displayCol,grouping);
    print(query)
    filteredDS=sqlContext.sql(query)
    filteredDS.show()
    
#filteredDS.coalesce(1).write.csv("Output/"+fn)