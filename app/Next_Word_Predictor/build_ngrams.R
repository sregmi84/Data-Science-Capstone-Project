# build_ngrams.R
# Author: Surabh
# Date: 02/13/2022
# Description: Generate ngram frequencies

### Load needed libraries
library(tm)
library(dplyr)
library(stringi)
library(stringr)
library(quanteda)
library(data.table)

### Prepare environment ###

rm(list = ls(all.names = TRUE))
setwd("~/Coursera/Data Science Capstone/Project/app/Next_Word_Predictor")
#memory.limit(64000) #Increase based on need

### Get data ###

trainURL <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip"
trainDataFile <- "data/Coursera-SwiftKey.zip"

if (!file.exists('data')) {
    dir.create('data')
}

if (!file.exists("data/final/en_US")) {
    tempFile <- tempfile()
    download.file(trainURL, tempFile)
    unzip(tempFile, exdir = "data")
    unlink(tempFile)
    rm(tempFile)
}

# Blogs
blogsFileName <- "data/final/en_US/en_US.blogs.txt"
con <- file(blogsFileName, open = "r")
blogs <- readLines(con, encoding = "UTF-8", skipNul = TRUE)
close(con)

# News
newsFileName <- "data/final/en_US/en_US.news.txt"
con <- file(newsFileName, open = "r")
news <- readLines(con, encoding = "UTF-8", skipNul = TRUE, warn = FALSE)
close(con)

# Twitter
twitterFileName <- "data/final/en_US/en_US.twitter.txt"
con <- file(twitterFileName, open = "r")
twitter <- readLines(con, encoding = "UTF-8", skipNul = TRUE)
close(con)

#print("Loaded training data")
#print(paste0("Number of lines per file (blogs):     ", format(length(blogs), big.mark = ",")))
#print(paste0("Number of lines per file (news):    ", format(length(news), big.mark = ",")))
#print(paste0("Number of lines per file (twitter): ", format(length(twitter), big.mark = ",")))
#print(paste0("Number of lines per file (total):   ", format(length(blogs) +
#                                                                length(news) +
#                                                                length(twitter), big.mark = ",")))

# remove variables no longer needed to free up memory
rm(con, trainURL, trainDataFile, blogsFileName, newsFileName, twitterFileName)

### Prepare data ###

# Set Sample Size
sampleSize = 0.0005

# Set Seed
set.seed(555)

# Sample all three data sets
sampleBlogs <- sample(blogs, length(blogs) * sampleSize, replace = FALSE)
sampleNews <- sample(news, length(news) * sampleSize, replace = FALSE)
sampleTwitter <- sample(twitter, length(twitter) * sampleSize, replace = FALSE)

# remove all non-English characters from the sampled data
sampleBlogs <- iconv(sampleBlogs, "latin1", "ASCII", sub = "")
sampleNews <- iconv(sampleNews, "latin1", "ASCII", sub = "")
sampleTwitter <- iconv(sampleTwitter, "latin1", "ASCII", sub = "")

# remove outliers such as very long and very short articles by only including the IQR
removeOutliers <- function(data) {
    first <- quantile(nchar(data), 0.25)
    third <- quantile(nchar(data), 0.75)
    data <- data[nchar(data) > first]
    data <- data[nchar(data) < third]
    return(data)
}

sampleBlogs <- removeOutliers(sampleBlogs)
sampleNews <- removeOutliers(sampleNews)
sampleTwitter <- removeOutliers(sampleTwitter)

# combine all three data sets into a single data set
sampleData <- c(sampleBlogs, sampleNews, sampleTwitter)

# get number of lines and words from the sample data set
sampleDataLines <- length(sampleData)
sampleDataWords <- sum(stri_count_words(sampleData))
print("Create sample data set")
print(paste0("Number of lines:  ", format(sampleDataLines, big.mark = ",")))
print(paste0("Number of words: ", format(sampleDataWords, big.mark = ",")))

# remove variables no longer needed to free up memory
rm(blogs, news, twitter, sampleBlogs, sampleNews, sampleTwitter)
rm(removeOutliers)

### Clean data ###

# Get file with profanity

# Doenload List of profane words from CMU
profanityURL <- "http://www.cs.cmu.edu/~biglou/resources/bad-words.txt"
profanityFile <- "data/cmu_list_of_bad_words_2022-02-13.txt"
if (!file.exists('data')) {
    dir.create('data')
}
if (!file.exists(profanityFile)) {
    download.file(profanityURL, profanityFile)
}

con <- file(profanityFile, open = "r")
profanity <- readLines(con, encoding = "UTF-8", skipNul = TRUE)
profanity <- profanity[-(which(profanity%in%c("screw","looser","^color")==TRUE))]
profanity <- iconv(profanity, "latin1", "ASCII", sub = "")
close(con)

# Remove profane words
sampleData <- removeWords(sampleData, profanity)

# Create function to clean the data
cleanData <- function (dataSet) {
    # convert text to lowercase
    dataSet <- tolower(dataSet)
    
    # remove URL, email addresses, Twitter handles and hash tags
    dataSet <- gsub("(f|ht)tp(s?)://(.*)[.][a-z]+", "", dataSet, ignore.case = FALSE, perl = TRUE)
    dataSet <- gsub("\\S+[@]\\S+", "", dataSet, ignore.case = FALSE, perl = TRUE)
    dataSet <- gsub("@[^\\s]+", "", dataSet, ignore.case = FALSE, perl = TRUE)
    dataSet <- gsub("#[^\\s]+", "", dataSet, ignore.case = FALSE, perl = TRUE)
    
    # remove ordinal numbers
    dataSet <- gsub("[0-9](?:st|nd|rd|th)", "", dataSet, ignore.case = FALSE, perl = TRUE)
    
    # remove profane words - Can be part of the function alternatively
    # dataSet <- removeWords(dataSet, profanity)
    
    # remove punctuation
    dataSet <- gsub("[^\\p{L}'\\s]+", "", dataSet, ignore.case = FALSE, perl = TRUE)
    
    # remove punctuation (leaving ')
    dataSet <- gsub("[.\\-!]", " ", dataSet, ignore.case = FALSE, perl = TRUE)
    
    # trim leading and trailing whitespace
    dataSet <- gsub("^\\s+|\\s+$", "", dataSet)
    dataSet <- stripWhitespace(dataSet)
    
    return(dataSet)
}

# Call the function to clean data
sampleData <- cleanData(sampleData)

# write sample data set to disk
sampleDataFileName <- "data/sampleData.txt"
con <- file(sampleDataFileName, open = "w")
writeLines(sampleData, con)
close(con)

# remove variables no longer needed to free up memory
rm(profanityURL, profanityFile, con, sampleDataFileName)

### Build Corpus ###

corpus <- corpus(sampleData)

### Build n-gram frequencies

getTopThree <- function(corpus) {
    first <- !duplicated(corpus$token)
    balance <- corpus[!first,]
    first <- corpus[first,]
    second <- !duplicated(balance$token)
    balance2 <- balance[!second,]
    second <- balance[second,]
    third <- !duplicated(balance2$token)
    third <- balance2[third,]
    return(rbind(first, second, third))
}

# Generate a token frequency dataframe. Do not remove stemwords because they are possible candidates for next word prediction.
tokenFrequency <- function(corpus, n = 1, rem_stopw = NULL) {
    #corpus <- dfm(corpus, ngrams = n) #Generates warning 
    corpus <- tokens_ngrams(tokens(corpus),n)
    corpus <- dfm(corpus)
    
    corpus <- colSums(corpus)
    total <- sum(corpus)
    corpus <- data.frame(names(corpus),
                         corpus,
                         row.names = NULL,
                         check.rows = FALSE,
                         check.names = FALSE,
                         stringsAsFactors = FALSE
    )
    colnames(corpus) <- c("token", "n")
    corpus <- mutate(corpus, token = gsub("_", " ", token))
    corpus <- mutate(corpus, percent = corpus$n / total)
    if (n > 1) {
        corpus$outcome <- word(corpus$token, -1)
        corpus$token <- word(string = corpus$token, start = 1, end = n - 1, sep = fixed(" "))
    }
    setorder(corpus, -n)
    corpus <- getTopThree(corpus)
    return(corpus)
}

# get top 3 words to initiate the next word prediction app
startWord <- word(corpus, 1)  # get first word for each document
startWord <- tokenFrequency(startWord, n = 1, NULL)  # determine most popular start words
startWordPrediction <- startWord$token[1:3]  # select top 3 words to start word prediction app
saveRDS(startWordPrediction, "data/startNextWordPredictor.RData")

# bigram
bigram <- tokenFrequency(corpus, n = 2, NULL)
saveRDS(bigram, "data/bigram.RData")
remove(bigram)

# trigram
trigram <- tokenFrequency(corpus, n = 3, NULL)
trigram <- trigram %>% filter(n > 1)
saveRDS(trigram, "data/trigram.RData")
remove(trigram)

# quadgram
quadgram <- tokenFrequency(corpus, n = 4, NULL)
quadgram <- quadgram %>% filter(n > 1)
saveRDS(quadgram, "data/quadgram.RData")
remove(quadgram)
