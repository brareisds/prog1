#include <stdio.h>
#define MAX 1024
int v[MAX]; // por quê?

    int main() {

        int n, tam;
        printf("Digite o tamanho do vetor:\n");
        scanf("%d",&n);

        while(n>MAX) {
            printf("Digite outro valor. Tamanho máximo %d\n", MAX);
            scanf("%d",&n);   
        }

    for(int i = 0; i<n; i++) {
        printf("Digite o valor de v[%d]:\n",i);
        scanf("%d",&v[i]);
    }
    
    
    for(int i = n-1; i>=0; i--) { /*com os indices ou com os valores do usuario*/
        printf("v[%d]: %d\n", i, v[i]);
    }
}
