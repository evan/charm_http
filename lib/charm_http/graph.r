
# Load data
data = read.table('tmp/chart.tsv', header=T)
headers = colnames(data)
nservices = ncol(data) - 1

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
yrange = c(0,curmax)

# Set up plot
png(paste(headers[1], ".png", sep=""), width=8, height=6, units = 'in', res=150)
plot(xrange, yrange, type="n", xlab="Dynos", ylab="Hz")
colors = rainbow(nservices)

# Add lines
for (i in 1:nservices) {
  data.spl = smooth.spline(data[[1]], data[[i + 1]], spar=0.3)
  lines(predict(data.spl, seq(xrange[1], xrange[2], by=0.1)), type="l", lwd=3, lty=1, col=colors[i])
}

# Add title and legend
title(headers[1])
legend(xrange[1], yrange[2], headers[2:ncol(data)], cex=0.8, col=colors, bg='white', fill=colors, border=colors)
