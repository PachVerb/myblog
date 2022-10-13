// layer size
const SIZE = 200;
// icon size
const ICONSIZE = [30, 32];
// icon scale
const SCALE = 1.5;

/**
 * 星光图
 * @map vMap creeper生成的map对象
 * @plusingIcon string 图标url
 */
function getPlusingDot  (map, plusingIcon)  {
    return {
        width: SIZE,
        height: SIZE,
        data: new Uint8Array(SIZE * SIZE * 4),
        context: null,
        onAdd: function() {
            const canvas = document.createElement("canvas");
            canvas.width = this.width;
            canvas.height = this.height;
            this.context = canvas.getContext("2d");
        },
        render: function() {
            const duration = 1000;
            const t = (performance.now() % duration) / duration;
            const radius = (SIZE / 2) * 0.3;
            const outerRadius = (SIZE / 2) * 0.35 * t + radius*0.5;
            const context = this.context;

            // draw outer circle
            context.clearRect(0, 0, this.width, this.height);
            context.beginPath();
            context.arc(this.width / 2, this.height / 2, outerRadius, 0, Math.PI * 2);
            context.fillStyle = "rgba(255, 200, 200," + (1 - t) + ")";
            context.fill();

            // draw inner circle
            context.beginPath();
            context.arc(this.width / 2, this.height / 2, radius, 0, Math.PI * 2);
            context.fillStyle = "rgba(255, 255, 100, 0.1)";
            context.strokeStyle = "#ffcccc";
            context.lineWidth = 1 + 4 * (1 - t);
            context.fill();
            context.stroke();

            // draw icon
            const icon = new Image();
            icon.src = plusingIcon;
            //console.log(icon);
            icon.onload = () => {
                context.drawImage(
                    icon,
                    (this.width - ICONSIZE[0] * SCALE) / 2,
                    (this.height - ICONSIZE[1] * SCALE) / 2,
                   
                );

                // update this image's data with data from the canvas
                this.data = context.getImageData(0, 0, this.width, this.height).data;

                // keep the map repainting should repaint here, otherwise the icon will not be drawn
                map.triggerRepaint();
            };

            // return `true` to let the map know that the image was updated
            return true;
        },
    };
};