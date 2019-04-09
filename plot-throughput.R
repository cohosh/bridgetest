require(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1], header=TRUE)

ggplot(data, aes(timestamp, bytes)) +
       geom_point() +
       geom_smooth() +
       xlab("Time") +
       ylab("# of transferred bytes") +
       theme_minimal()

dev.off()

ggsave("throughput.pdf",
       width = 5,
       height = 2.5)
