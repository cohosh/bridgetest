library(data.table)
library(ggplot2)


gala.vpn.working <- {
	# Evaluate these as.POSIXct calls in the closure's environment
	# so they won't be re-evaluated on every call.
	pidbug.start <- as.POSIXct("2016-12-28 03:25:06", tz="UTC")
	pidbug.end <- as.POSIXct("2017-01-12 19:00:37", tz="UTC")
	off.20170408T062000 <- as.POSIXct("2017-04-08 06:20:00", tz="UTC")
	on.20170426T124637 <- as.POSIXct("2017-04-26 12:46:37", tz="UTC")
	off.20170502T051500 <- as.POSIXct("2017-05-02 05:15:00", tz="UTC")
	function(timestamp) {
		(timestamp < pidbug.start) |
		(pidbug.end <= timestamp & timestamp < off.20170408T062000) |
		(on.20170426T124637 <= timestamp & timestamp < off.20170502T051500)
	}
}


args <- commandArgs(trailingOnly=T)

x <- data.table()
for (filename in args) {
	x <- rbind(x, fread(filename))
}
x$timestamp <- as.POSIXct(x$timestamp, tz="UTC")
# Filter out the times the gala VPN wasn't working
# (otherwise it looks like timeouts; i.e. blocking)
x <- x[site!="gala" | gala.vpn.working(timestamp)]

x.max <- x[ , .SD[which.max(percent)], by=.(site, runid, nickname)]
setkey(x.max, site, runid, nickname)


cat("
{{{#!html
<table class=\"wiki\">
<tr><th>bridge</th><th>US average bootstrap %</th><th>KZ average bootstrap %</th></tr>
")
ramp <- colorRamp(c("#d6756b", "#f7fbff"))
summ <- x.max[gala.vpn.working(timestamp), .(.N, avg.percent=mean(percent)), by=.(site, nickname)]
for (nick in unique(x$nickname)) {
	bear <- summ[site=="bear" & nickname==nick]
	gala <- summ[site=="gala" & nickname==nick]
	cat(sprintf("<tr><td>%s</td><td align=right style=\"background: %s\">%.2f%%</td><td align=right style=\"background: %s\">%.2f%%</td></tr>\n",
		nick, rgb(ramp(bear$avg.percent/100)/255), bear$avg.percent, rgb(ramp(gala$avg.percent/100)/255), gala$avg.percent))
}
cat("</table>
}}}
")


pdf(width=8.5, height=14)

# runids <- unique(x$runid)
# runids <- runids[order(runids)]
# p <- ggplot(x[x$runid %in% runids[(length(runids)-2):(length(runids)-1)], ])
# p <- p + geom_step(aes(timestamp, percent, group=sprintf("%s-%s", runid, nickname), color=nickname))
# p <- p + scale_y_continuous(limits=c(0, 100), breaks=seq(0, 100, 10))
# p <- p + theme_bw()
# p

# p <- ggplot(x.max)
# p <- p + geom_point(aes(nickname, percent, color=site), alpha=0.4, size=0.7, position=position_jitter(width=0.3, height=0))
# p <- p + scale_y_continuous(limits=c(0, 100))
# p <- p + coord_flip()
# p <- p + theme_bw()
# p <- p + guides(color=guide_legend(override.aes=list(alpha=1, size=2)))
# p

tmp <- x.max
tmp$site <- factor(tmp$site, levels=c("bear", "gala"), labels=c("US", "KZ"))
p <- ggplot(tmp)
p <- p + geom_point(aes(timestamp, percent, color=site, shape=site, size=site), alpha=0.4)
p <- p + facet_grid(nickname ~ .)
p <- p + scale_y_continuous(limits=c(0, 105))
p <- p + scale_color_brewer(palette="Set1")
p <- p + scale_shape_manual(values=c(US=4, KZ=16))
p <- p + scale_size_manual(values=c(US=1.0, KZ=1.0))
p <- p + theme_bw()
p <- p + theme(strip.text.y=element_text(angle=0))
p <- p + theme(legend.position="top")
p <- p + guides(color=guide_legend(override.aes=list(alpha=1, size=2.5)))
p
