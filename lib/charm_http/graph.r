
# Load data
data = read.table('tmp/data.ssv', header=T, sep=" ")
headers = colnames(data)
nservices = ncol(data) - 1
nrows = nrow(data)

# Get X range
xrange = range(data[1])

# Get Y range
ymax = 0
for (i in 1:nservices) {
  curmax = max(data[i + 1])
  if (curmax > ymax) {
    ymax = curmax
  }
}
yrange = c(0,ymax)

# Set up plot
png(paste(headers[1], ".png", sep=""), width=8, height=6, units = 'in', res=150)
colors = rainbow(nservices)

# Add lines
if (nrows < 2) {
  data.mx = as.matrix(data[2:ncol(data)])
  par(las=3, mar=c(5,5,3,1))
  barplot(data.mx, yaxp=c(0,ymax,4), beside=T, col=colors, xlab=paste(data[1,1], "dynos"), ylab="Responses per second", border=T, names.arg=rep("", nservices))
} else {
  plot(xrange, yrange, type="n", xlab="Dynos", ylab="Responses per second")
  for (i in 1:nservices) {
    if (nrows < 4) {
      lines(data[[1]], data[[i + 1]], type="l", lwd=3, lty=1, col=colors[i])
    } else {
      data.spl = smooth.spline(data[[1]], data[[i + 1]], spar=0.3)
      lines(predict(data.spl, seq(xrange[1], xrange[2], by=0.1)), type="l", lwd=3, lty=1, col=colors[i])
    }
  }
}

# Add title and legend
title(headers[1])
legend(xrange[1], yrange[2] * 0.95, headers[2:ncol(data)], cex=0.8, col=colors, bg='transparent', fill=colors, border=colors)
