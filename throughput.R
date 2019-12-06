library("ggplot2")
library("reshape2")
library("plyr")
library(data.table)

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1], header=TRUE)
bootstrap <- read.csv(args[2], header=TRUE)

latencies <- data[,2]/(1000*data[,3])
len <- length(latencies)

data <- latencies[!is.na(latencies)]

print(paste("Number of failed downloads: ", len - length(data), sep=""))
print(paste("Average throughput (KB/s): ", mean(data), sep=""))
print(paste("Standard deviation: ", sd(data), sep=""))

##latency
ggdata <- data.frame(x = data)

ggplot(ggdata, aes(x=x)) + 
  stat_ecdf(show.legend=FALSE) + labs(x='Throughput (KB/s)', y='CDF') + 
  theme(text = element_text(size=20,family="Times")) + theme_bw() + theme(text = element_text(size=20,family="Times"))

ggsave("throughput.pdf",
       width = 5,
       height = 5)


setDT(bootstrap)
x.max <- bootstrap[ , .SD[which.max(percent)], by=.(site, runid, nickname)]
setkey(x.max, site, runid)

ggdata = data.frame(x = x.max$percent)

ggplot(ggdata, aes(x=x)) + 
  stat_ecdf(show.legend=FALSE) + labs(x='Bootstrap progress (%)', y='CDF') + 
  theme(text = element_text(size=20,family="Times")) + theme_bw() + theme(text = element_text(size=20,family="Times"))

ggsave("bootstrap.pdf",
       width = 5,
       height = 5)


print(paste("Number of failed snowflakes: ", length(x.max$percent[x.max$percent <= 10]), sep=""))
print(paste("Number of full bootstraps: ", length(x.max$percent[x.max$percent == 100]), sep=""))
print(paste("Average bootstrap progress: ", mean(x.max$percent), sep=""))
