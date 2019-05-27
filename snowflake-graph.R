library(data.table)
library(ggplot2)


args <- commandArgs(trailingOnly=T)

x <- data.table()
for (filename in args) {
	x <- rbind(x, fread(filename))
}
x$timestamp <- as.POSIXct(x$timestamp, tz="UTC")
# Filter out the times the cn VPN wasn't working
# (otherwise it looks like timeouts; i.e. blocking)

x.max <- x[ , .SD[which.max(percent)], by=.(site, runid, ip)]
setkey(x.max, site, runid, ip)


cat("
{{{#!html
<table class=\"wiki\">
<tr><th>bridge</th><th>CA average bootstrap %</th><th>CN average bootstrap %</th></tr>
")
ramp <- colorRamp(c("#d6756b", "#f7fbff"))
summ <- x.max[, .(.N, avg.percent=mean(percent)), by=.(site, ip)]
for (nick in unique(x$ip)) {
	na <- summ[site=="na" & ip==nick]
	cn <- summ[site=="cn" & ip==nick]
	cat(sprintf("<tr><td>%s</td><td align=right style=\"background: %s\">%.2f%%</td><td align=right style=\"background: %s\">%.2f%%</td></tr>\n",
		nick, rgb(ramp(na$avg.percent/100)/255), na$avg.percent, rgb(ramp(cn$avg.percent/100)/255), cn$avg.percent))
}
cat("</table>
}}}
")


pdf(width=8.5, height=14)

# runids <- unique(x$runid)
# runids <- runids[order(runids)]
# p <- ggplot(x[x$runid %in% runids[(length(runids)-2):(length(runids)-1)], ])
# p <- p + geom_step(aes(timestamp, percent, group=sprintf("%s-%s", runid, ip), color=ip))
# p <- p + scale_y_continuous(limits=c(0, 100), breaks=seq(0, 100, 10))
# p <- p + theme_bw()
# p

# p <- ggplot(x.max)
# p <- p + geom_point(aes(ip, percent, color=site), alpha=0.4, size=0.7, position=position_jitter(width=0.3, height=0))
# p <- p + scale_y_continuous(limits=c(0, 100))
# p <- p + coord_flip()
# p <- p + theme_bw()
# p <- p + guides(color=guide_legend(override.aes=list(alpha=1, size=2)))
# p

tmp <- x.max
tmp$site <- factor(tmp$site, levels=c("na", "cn"), labels=c("CA", "CN"))
p <- ggplot(tmp)
p <- p + geom_point(aes(timestamp, percent, color=site, shape=site, size=site), alpha=0.4)
p <- p + facet_grid(ip ~ .)
p <- p + scale_y_continuous(limits = c(0,105), breaks=c(20,40,60,80,100), labels=c("Gathering", "Signaling","Connecting","Data", "Done"))
p <- p + scale_color_brewer(palette="Set1")
p <- p + scale_shape_manual(values=c(CA=4, CN=16))
p <- p + scale_size_manual(values=c(CA=1.0, CN=1.0))
p <- p + theme_bw()
p <- p + theme(strip.text.y=element_text(angle=0))
p <- p + theme(legend.position="top")
p <- p + guides(color=guide_legend(override.aes=list(alpha=1, size=2.5)))
p
