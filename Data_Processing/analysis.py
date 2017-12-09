#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession, functions, types, SQLContext, Row
from pyspark.sql.functions import *
import sys
from optparse import OptionParser
from datetime import datetime

def get_month(date):
    return datetime.strptime(date[4:6], "%m").strftime("%b")


conf = SparkConf().setAppName('BDProject')
sc = SparkContext.getOrCreate(conf=conf)
spark = SparkSession.builder.appName('BDProject').getOrCreate()
sqlContext = SQLContext(sc)
INPUT_FOLDER = 'Extracted'

def get_sql_query(displayCol, conditions, grouping, cond_string):
    """

    :param displayCol: String
        Column to display
    :param conditions: String
        Condition filter to execture query
    :param grouping: String
        Result grouping
    :param cond_string: String
        Formed condition string to execute where query
    :return: String
        String representation of query
    """
    if (displayCol != None and conditions != None and grouping != None):
        return '''SELECT {0} FROM data WHERE {1} GROUP BY {2}'''.format(displayCol, cond_string, grouping)

    if (displayCol != None and conditions == None and grouping != None):
        print("No conditions were set")
        return '''SELECT {0} FROM data GROUP BY {1}'''.format(displayCol, grouping)

    if (displayCol != None and conditions != None and grouping == None):
        print("No grouping were set")
        return '''SELECT {0} FROM data WHERE {1}'''.format(displayCol, cond_string)

    if (displayCol != None and conditions == None and grouping == None):
        print("No conditon or grouping were set")
        return '''SELECT {0} FROM data'''.format(displayCol)


def main():
    #define all udf
    my_month = functions.udf(lambda date:datetime.strptime(date[4:6], "%m").strftime("%b"), types.StringType())

    #Parse for getting argument passed to program
    parser = OptionParser()
    parser.add_option("--col", "--column", dest="column", help="Sepcifies columns to display")
    parser.add_option("--con", "--condition", dest="condition", help="Specifies columns where conditions will be apllied to")
    parser.add_option("--grp", "--group", dest="group", help="Specifies Values of the condiions")
    parser.add_option("--out", "--output", dest="output", help="Specifies output directory")
    (options, args) = parser.parse_args()

    #Processing command line args
    displayCol = options.column
    conditions = options.condition
    grouping = options.group
    output_dir = options.output

    if output_dir == None:
        output_dir = 'output'

    if(displayCol==None):
        print("No columns were selected,exiting")
        sys.exit()

    #reading the crime data
    data = spark.read.csv("{}/".format(INPUT_FOLDER), header=True, sep='\t')

    data = data.withColumn('MONTH', my_month(data['INCIDDTE']))
    data.createOrReplaceTempView('data')

    #getting codes for location, offenders, offencecode, victims
    loc = spark.read.csv("MetaData/location.csv", header=True)
    loc.createOrReplaceTempView('loc')

    offender = spark.read.csv("MetaData/offenders.csv", header=True)
    offender.createOrReplaceTempView('offender')

    victims = spark.read.csv("MetaData/bias_victims.csv", header=True)
    victims.createOrReplaceTempView('victims')

    offencecode = spark.read.csv("MetaData/offencecode.csv", header=True)
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
    cond_string = ""
    if(conditions!=None):
        condition=conditions.split(",")
        valfalg=False
        for con in condition:
            if con == 'AND' or con=='OR' or con=='NOT':
                cond_string=cond_string + " "
                cond_string=cond_string + con
                cond_string=cond_string + " "

            else:
                if(valfalg==False):
                    cond_string=cond_string + con
                    valfalg=True

                else:
                    if(con.isalpha()):
                        cond_string=cond_string + '"'
                        cond_string=cond_string + con
                        cond_string=cond_string + '"'
                    else:
                        cond_string=cond_string + con
                    valfalg=False

    query = get_sql_query(displayCol, conditions, grouping, cond_string)
    filteredDS=sqlContext.sql(query)
    filteredDS.show()
    filteredDS.coalesce(1).write.csv(output_dir)


if __name__ == "__main__":
    main()
