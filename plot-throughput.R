require(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1], header=TRUE)

ggplot(data, aes(timestamp, bytes)) +
       geom_point() +
       geom_smooth() +
       facet_wrap(. ~ test, ncol=2, scales="free") +
       xlab("Time") +
       ylab("# of transferred bytes") +
       theme_minimal()

dev.off()

tests <- length(unique(data[,"test"]))
tests

ggsave("throughput.pdf",
       width = 5*2,
       height = 2.5*tests/2)
