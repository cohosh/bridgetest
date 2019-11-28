library("ggplot2")
library("reshape2")
library("plyr")

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1], header=TRUE)

latencies <- data[,2]/(1000*data[,3])
len <- length(latencies)

data <- latencies[!is.na(latencies)]

print(paste("Number of failed snowflakes: ", len - length(data), sep=""))
print(paste("Average throuhput: ", mean(data), sep=""))
print(paste("Standard deviation: ", sd(data), sep=""))

##latency
ggdata <- data.frame(x = data)

ggplot(ggdata, aes(x=x)) + 
  stat_ecdf(show.legend=FALSE) + labs(x='Throughput (KB/s)', y='CDF') + 
  theme(text = element_text(size=20,family="Times")) + theme_bw() + theme(text = element_text(size=20,family="Times"))

ggsave("throughput.pdf",
       width = 5,
       height = 5)
