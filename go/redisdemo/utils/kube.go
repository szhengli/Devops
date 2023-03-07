package utils

import (
	"context"
	"fmt"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/utils/pointer"
	"log"
	"strconv"
	"sync"
	"time"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

const kubeConfigPath = "/root/.kube/config"

func scaleDeploy(ctx context.Context, wg *sync.WaitGroup, clientset *kubernetes.Clientset, service string, amount *int32) {

	defer wg.Done()
	deploymentsClient := clientset.AppsV1().Deployments("prodv5")
	dep, err := deploymentsClient.Get(ctx, service, metav1.GetOptions{})

	if err != nil {
		panic(err)
	}
	dep.Spec.Replicas = amount
	_, err = deploymentsClient.Update(ctx, dep, metav1.UpdateOptions{})
	if err != nil {
		panic(err)
	}

	for {
		time.Sleep(1 * time.Second)
		if dep, err := deploymentsClient.Get(ctx, service, metav1.GetOptions{}); err != nil {
			panic(err)
		} else {
			if dep.Status.ReadyReplicas == *amount {
				fmt.Println(service + "has been updated ! ")
				break
			} else {
				fmt.Println(service + ": " + strconv.Itoa(int(dep.Status.ReadyReplicas)))
			}
		}
	}
}

func adjustService(enable bool) {

	ctx := context.TODO()

	config, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
	if err != nil {
		panic(err)
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}

	amounts, _ := clientset.CoreV1().ConfigMaps("prodv5").Get(ctx, "amounts", metav1.GetOptions{})
	amountConfig := amounts.Data

	fmt.Println("waiting ....")

	var wg sync.WaitGroup
	wg.Add(len(amountConfig))

	if enable {
		log.Println("switch to backup, scale the pods in backup to normal ++++++++")
		for service, amount := range amountConfig {
			fmt.Println("scale for " + service)
			amount, _ := strconv.Atoi(amount)
			number := pointer.Int32(int32(amount))
			go scaleDeploy(ctx, &wg, clientset, service, number)
		}
	} else {
		log.Println("switch to normal, scale the pods in backup to zero ------")
		for service, _ := range amountConfig {
			number := pointer.Int32(0)
			go scaleDeploy(ctx, &wg, clientset, service, number)
		}

	}
	wg.Wait()
}
