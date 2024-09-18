#include <stdio.h>
#include "lab.h"
#define STB_IMAGE_IMPLEMENTATION

#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION

#include "stb_image_write.h"
#include <time.h>
typedef struct image_size {
    int x;
    int y;
} image_size;

void gaussianBlur(unsigned char* src, int x, int y, int n, unsigned char* dst, float kernel[3][3]) {
    int i, j, k, l;
    float sum;
    float pixel;

    for (int offset = 0; offset < n; ++offset) {

        // Применяем свертку для каждого пикселя изображения
        for (i = 0; i < y; i++) {

            for (j = 0; j < x; j++) {
                sum = 0;

                // Проходим по окрестности 3x3 пикселя
                for (k = -1; k <= 1; k++) {
                    for (l = -1; l <= 1; l++) {
                        // Вычисляем сумму значений пикселей, умноженных на соответствующие элементы матрицы свертки
                        pixel = src[n * ((i + k) * (x+2) + (j + l)) + offset];
                        sum += pixel * kernel[k + 1][l + 1];
                    }
                }

                // Записываем результат в выходное изображение
                dst[n * (i * x + j) + offset] = (unsigned char)sum;
            }
        }
    }
}


void extendImage(unsigned char* src, int x, int y,int n, unsigned char* dst) {
    int extendedX = x + 2; // Расширенная ширина изображения
    int extendedY = y + 2; // Расширенная высота изображения

    for (int offset = 0; offset < n; ++offset) {
        // Копирование центральной части изображения
        for (int i = 0; i < y; i++) {
            for (int j = 0; j < x; j++) {
                dst[n*((i + 1) * extendedX + (j + 1))+offset] = src[n*(i * x + j)+offset];
            }
        }

        // Копирование верхней и нижней границы
        for (int j = 0; j < x; j++) {
            dst[n*(j+1)+offset] = src[n*j+offset]; // Верхняя граница
            dst[n*((extendedY - 1) * extendedX + (j + 1))+offset] = src[n*((y - 1) * x + j)+offset]; // Нижняя граница
        }

        // Копирование левой и правой границы
        for (int i = 0; i < y; i++) {
            dst[n*((i + 1) * extendedX)+offset] = src[n*i * x+offset]; // Левая граница
            dst[n*((i + 1) * extendedX + extendedX - 1)+offset] = src[n*(i * x + x - 1)+offset]; // Правая граница
        }

        // Копирование угловых пикселей
        dst[offset] = src[offset]; // Левый верхний угол
        dst[n*(extendedX - 1)+offset] = src[n*(x - 1)+offset]; // Правый верхний угол
        dst[n*((extendedY - 1) * extendedX)+offset] = src[n*((y - 1) * x)+offset]; // Левый нижний угол
        dst[n*(extendedY * extendedX - 1)+offset] = src[n*(y * x - 1)+offset]; // Правый нижний угол
    }
}


int main() {
    float kernel[3][3] = {
            {1, 2, 1},
            {2, 4, 2},
            {1, 2, 1}};
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            kernel[i][j] = kernel[i][j] / 16;
        }
    }

    image_size new_image;

    int x, y, n, len_fname = 15;
    char* filename = (char*) malloc(len_fname);
    unsigned char* src = NULL;
    do {
        printf("Enter the name of picture:\n");
        scanf("%s", filename);

        src = stbi_load(filename, &x, &y, &n, 0);
    } while (src == NULL);

    image_size old_image = {x, y};

    unsigned char* dst1 = (unsigned char*) malloc(old_image.x * old_image.y * n);
    unsigned char* dst2 = (unsigned char*) malloc(old_image.x * old_image.y * n);
    unsigned char* extended = (unsigned char*) malloc((old_image.x+2) * (old_image.y+2) * n);
    
    extendImage(src, x, y,n, extended);
    double time_spent1=0.0;
    double time_spent2=0.0;
    clock_t begin=clock();
    gaussianBlur(&extended[n*(old_image.x+2+1)], old_image.x, old_image.y, n, dst1, kernel);
    clock_t end= clock();
    time_spent1=(double)(end-begin)/ CLOCKS_PER_SEC;
    begin=clock();
    gaussianBlur_asm(&extended[n*(old_image.x+2+1)], old_image.x, old_image.y, n, dst2, kernel);
	end=clock();
	time_spent2=(double)(end-begin)/ CLOCKS_PER_SEC;
	printf("C: %f sec\n", time_spent1);
	printf("asm: %f sec\n", time_spent2);
    char* output1 = "result_C.jpg";
    stbi_write_jpg(output1, old_image.x, old_image.y, n, dst1, 100);
    char* output2="result_asm.jpg";
    stbi_write_jpg(output2, old_image.x, old_image.y, n, dst2, 100);

    stbi_image_free(src);
    stbi_image_free(dst1);
    stbi_image_free(dst2);
    free(filename);
    return 0;
}
