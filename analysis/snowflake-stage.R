library(data.table)
library(ggplot2)


args <- commandArgs(trailingOnly=T)

x <- data.table()
for (filename in args) {
	x <- rbind(x, fread(filename))
}
x$timestamp <- as.POSIXct(x$timestamp, tz="UTC")

setDT(x)
x.max <- x[ , .SD[which.max(percent)], by=.(site, runid, probeid)]
setkey(x.max, site, runid)

ggdata = data.frame(x = x.max$percent)

ggplot(ggdata, aes(x=x)) + 
  geom_bar(stat="count", width= 10) + labs(x='Snowflake stage', y='Count') + 
  theme(text = element_text(size=12,family="Times")) + theme_bw() + theme(text = element_text(size=12,family="Times")) +
  scale_x_continuous(limits=c(10,110), breaks=c(20,40,60,80,100), labels=c("Gathering", "Signaling","Connecting","Data", "Done"))

ggsave("stage.pdf",
       width = 7,
       height = 5)


print(paste("Number of successful snowflake connections: ", length(x.max$percent[x.max$percent == 100]), sep=""))
print(paste("Average connection progress: ", mean(x.max$percent), sep=""))
